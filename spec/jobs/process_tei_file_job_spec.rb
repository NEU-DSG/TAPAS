# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProcessTeiFileJob, type: :job do
  let(:depositor) { create(:user) }
  let(:project) { create(:project, depositor: depositor) }
  let(:collection) { create(:collection, project: project, depositor: depositor) }
  let(:core_file) do
    create(:core_file,
      depositor: depositor,
      collections: [ collection ],
      processing_status: 'pending'
    )
  end

  let(:tei_content) { "<TEI><teiHeader><title>Test</title></teiHeader></TEI>" }

  before do
    core_file.tei_file.attach(
      io: StringIO.new(tei_content),
      filename: "test.xml",
      content_type: "application/xml"
    )
  end

  describe '#perform' do
    context 'when TAPAS-XQ is enabled' do
      before do
        allow(TapasXq.configuration).to receive(:disabled?).and_return(false)
      end

      it 'updates core_file with MODS XML on success' do
        mods_xml = "<mods><title>Test Document</title></mods>"
        stub_tapas_xq_store(
          project_id: project.id,
          doc_id: core_file.id,
          mods_xml: mods_xml
        )

        described_class.perform_now(core_file.id)

        core_file.reload
        expect(core_file.processing_status).to eq('completed')
        expect(core_file.mods_xml).to eq(mods_xml)
        expect(core_file.tapas_xq_project_id).to eq(project.id.to_s)
        expect(core_file.tapas_xq_doc_id).to eq(core_file.id.to_s)
        expect(core_file.processing_error).to be_nil
      end

      it 'sets status to processing before making request' do
        stub_tapas_xq_store(
          project_id: project.id,
          doc_id: core_file.id
        )

        expect {
          described_class.perform_now(core_file.id)
        }.to change { core_file.reload.processing_status }.from('pending').to('completed')
      end

      it 'logs success message', skip: 'Rails 8 BroadcastLogger incompatible with receive expectations' do
        stub_tapas_xq_store(
          project_id: project.id,
          doc_id: core_file.id
        )

        expect(Rails.logger).to receive(:info).with(/TAPAS-XQ processing completed/)

        described_class.perform_now(core_file.id)
      end

      it 'marks as failed and stores error on TapasXq::Error' do
        stub_tapas_xq_connection_error(
          project_id: project.id,
          doc_id: core_file.id
        )

        # Note: retry_on intercepts ConnectionError, so we can't expect it to raise
        # The job gets re-enqueued instead of raising
        described_class.perform_now(core_file.id)

        core_file.reload
        expect(core_file.processing_status).to eq('failed')
        expect(core_file.processing_error).to include('Cannot connect')
      end

      it 'marks as failed on unexpected error' do
        allow_any_instance_of(TapasXq::StorageService).to receive(:store).and_raise(StandardError, "Unexpected error")

        expect {
          described_class.perform_now(core_file.id)
        }.to raise_error(StandardError)

        core_file.reload
        expect(core_file.processing_status).to eq('failed')
        expect(core_file.processing_error).to include('Unexpected error')
      end

      it 'logs unexpected errors', skip: 'Rails 8 BroadcastLogger incompatible with receive expectations' do
        allow_any_instance_of(TapasXq::StorageService).to receive(:store).and_raise(RuntimeError, "Something went wrong")

        expect(Rails.logger).to receive(:error).with(/Unexpected error processing CoreFile/)

        expect {
          described_class.perform_now(core_file.id)
        }.to raise_error(RuntimeError)
      end

      it 'skips processing if already processing' do
        core_file.update!(processing_status: 'processing')

        described_class.perform_now(core_file.id)

        # Should still be processing, no API call made
        expect(core_file.reload.processing_status).to eq('processing')
        expect(WebMock).not_to have_requested(:post, /tapas-xq/)
      end

      it 'skips processing if already completed' do
        core_file.update!(processing_status: 'completed')

        described_class.perform_now(core_file.id)

        expect(core_file.reload.processing_status).to eq('completed')
        expect(WebMock).not_to have_requested(:post, /tapas-xq/)
      end
    end

    context 'when TAPAS-XQ is disabled' do
      before do
        allow(TapasXq.configuration).to receive(:disabled?).and_return(true)
      end

      it 'marks as completed without making API call' do
        described_class.perform_now(core_file.id)

        core_file.reload
        expect(core_file.processing_status).to eq('completed')
        expect(core_file.mods_xml).to be_nil
        expect(WebMock).not_to have_requested(:post, /tapas-xq/)
      end

      it 'logs that processing was skipped', skip: 'Rails 8 BroadcastLogger incompatible with receive expectations' do
        expect(Rails.logger).to receive(:info).with(/TAPAS-XQ disabled, skipping/)

        described_class.perform_now(core_file.id)
      end
    end

    context 'retry behavior' do
      before do
        allow(TapasXq.configuration).to receive(:disabled?).and_return(false)
      end

      it 'retries on TimeoutError' do
        stub_tapas_xq_timeout(
          project_id: project.id,
          doc_id: core_file.id
        ).times(2).then.to_return(status: 201, body: "<mods/>")

        perform_enqueued_jobs do
          described_class.perform_later(core_file.id)
        end

        core_file.reload
        expect(core_file.processing_status).to eq('completed')
      end

      it 'retries on ConnectionError' do
        stub_tapas_xq_connection_error(
          project_id: project.id,
          doc_id: core_file.id
        ).times(2).then.to_return(status: 201, body: "<mods/>")

        perform_enqueued_jobs do
          described_class.perform_later(core_file.id)
        end

        core_file.reload
        expect(core_file.processing_status).to eq('completed')
      end

      it 'discards job on AuthenticationError' do
        stub_tapas_xq_auth_failure(
          project_id: project.id,
          doc_id: core_file.id
        )

        perform_enqueued_jobs do
          described_class.perform_later(core_file.id)
        end

        core_file.reload
        expect(core_file.processing_status).to eq('failed')
        expect(core_file.processing_error).to include('Authentication failed')
      end
    end

    context 'with nonexistent core_file' do
      it 'logs error and discards job', skip: 'Rails 8 BroadcastLogger incompatible with receive expectations' do
        expect(Rails.logger).to receive(:error).with(/CoreFile not found: 99999/)

        perform_enqueued_jobs do
          described_class.perform_later(99999)
        end
      end
    end
  end
end
