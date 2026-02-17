# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TapasXq::StorageService, type: :service do
  let(:depositor) { create(:user) }
  let(:project) { create(:project, depositor: depositor) }
  let(:collection) { create(:collection, project: project, depositor: depositor) }
  let(:core_file) do
    create(:core_file,
      depositor: depositor,
      collections: [ collection ],
      title: "Test TEI File",
      tei_authors: "Author 1|Author 2",
      tei_contributors: "Contributor 1",
      is_public: true
    )
  end

  let(:tei_content) { "<TEI><teiHeader><title>Test</title></teiHeader></TEI>" }

  before do
    # Attach TEI file to core_file
    core_file.tei_file.attach(
      io: StringIO.new(tei_content),
      filename: "test.xml",
      content_type: "application/xml"
    )
  end

  describe '#store' do
    context 'with valid core_file' do
      it 'posts to TAPAS-XQ with correct parameters' do
        mods_xml = "<mods><title>Test</title></mods>"
        stub_tapas_xq_store(
          project_id: project.id,
          doc_id: core_file.id,
          mods_xml: mods_xml
        )

        service = described_class.new(core_file)
        result = service.store

        expect(result[:mods_xml]).to eq(mods_xml)
        expect(result[:tapas_xq_project_id]).to eq(project.id.to_s)
        expect(result[:tapas_xq_doc_id]).to eq(core_file.id.to_s)
      end

      it 'sends all required form parameters' do
        stub = stub_tapas_xq_store(
          project_id: project.id,
          doc_id: core_file.id
        )

        service = described_class.new(core_file)
        service.store

        expect(stub).to have_been_requested
      end

      it 'includes collection IDs as comma-separated string' do
        collection2 = create(:collection, project: project, depositor: depositor)
        core_file.collections << collection2

        mock_client = instance_double(TapasXq::Client)
        allow(mock_client).to receive(:post).and_return("<mods/>")

        described_class.new(core_file, client: mock_client).store

        expect(mock_client).to have_received(:post).with(
          anything,
          hash_including(
            collections: satisfy { |v| v.split(",").map(&:to_i).sort == [ collection.id, collection2.id ].sort }
          )
        )
      end

      it 'formats is-public parameter as string "false" when false' do
        core_file.update!(is_public: false)

        mock_client = instance_double(TapasXq::Client)
        allow(mock_client).to receive(:post).and_return("<mods/>")

        described_class.new(core_file, client: mock_client).store

        expect(mock_client).to have_received(:post).with(
          anything,
          hash_including('is-public': "false")
        )
      end

      it 'formats is-public parameter as string "true" when true' do
        mock_client = instance_double(TapasXq::Client)
        allow(mock_client).to receive(:post).and_return("<mods/>")

        described_class.new(core_file, client: mock_client).store

        expect(mock_client).to have_received(:post).with(
          anything,
          hash_including('is-public': "true")
        )
      end

      it 'sends title in request params' do
        mock_client = instance_double(TapasXq::Client)
        allow(mock_client).to receive(:post).and_return("<mods/>")

        described_class.new(core_file, client: mock_client).store

        expect(mock_client).to have_received(:post).with(
          anything,
          hash_including(title: "Test TEI File")
        )
      end

      it 'sends authors and contributors as pipe-separated strings when present' do
        mock_client = instance_double(TapasXq::Client)
        allow(mock_client).to receive(:post).and_return("<mods/>")

        described_class.new(core_file, client: mock_client).store

        expect(mock_client).to have_received(:post).with(
          anything,
          hash_including(
            authors: "Author 1|Author 2",
            contributors: "Contributor 1"
          )
        )
      end

      it 'sends file content in request params' do
        mock_client = instance_double(TapasXq::Client)
        allow(mock_client).to receive(:post).and_return("<mods/>")

        described_class.new(core_file, client: mock_client).store

        expect(mock_client).to have_received(:post).with(
          anything,
          hash_including(file: tei_content)
        )
      end

      it 'sends empty string for nil authors and contributors' do
        core_file.update!(tei_authors: nil, tei_contributors: nil)

        mock_client = instance_double(TapasXq::Client)
        allow(mock_client).to receive(:post).and_return("<mods/>")

        described_class.new(core_file, client: mock_client).store

        expect(mock_client).to have_received(:post).with(
          anything,
          hash_including(authors: "", contributors: "")
        )
      end
    end

    context 'with invalid prerequisites' do
      it 'raises ArgumentError if TEI file not attached' do
        core_file.tei_file.purge
        service = described_class.new(core_file)

        expect {
          service.store
        }.to raise_error(ArgumentError, /TEI file not attached/)
      end

      it 'raises ArgumentError if core_file has no project' do
        core_file.collections.clear
        service = described_class.new(core_file)

        expect {
          service.store
        }.to raise_error(ArgumentError, /CoreFile must have project/)
      end
    end

    context 'with TAPAS-XQ errors' do
      it 'propagates ConnectionError' do
        stub_tapas_xq_connection_error(
          project_id: project.id,
          doc_id: core_file.id
        )

        service = described_class.new(core_file)

        expect {
          service.store
        }.to raise_error(TapasXq::ConnectionError)
      end

      it 'propagates TimeoutError' do
        stub_tapas_xq_timeout(
          project_id: project.id,
          doc_id: core_file.id
        )

        service = described_class.new(core_file)

        expect {
          service.store
        }.to raise_error(TapasXq::TimeoutError)
      end

      it 'propagates AuthenticationError' do
        stub_tapas_xq_auth_failure(
          project_id: project.id,
          doc_id: core_file.id
        )

        service = described_class.new(core_file)

        expect {
          service.store
        }.to raise_error(TapasXq::AuthenticationError)
      end

      it 'propagates ServerError on 500 response' do
        # Per API docs: a 500 may indicate MODS generation failed while TEI/TFE
        # were still stored. The service raises ServerError in either case —
        # distinguishing partial vs full failure is a caller responsibility.
        stub_tapas_xq_store_failure(
          project_id: project.id,
          doc_id: core_file.id,
          status: 500
        )

        service = described_class.new(core_file)

        expect {
          service.store
        }.to raise_error(TapasXq::ServerError)
      end

      it 'logs error when storage fails' do
        stub_tapas_xq_connection_error(
          project_id: project.id,
          doc_id: core_file.id
        )

        service = described_class.new(core_file)

        expect(Rails.logger).to receive(:error).with(/TAPAS-XQ storage failed/)

        expect {
          service.store
        }.to raise_error(TapasXq::ConnectionError)
      end
    end

    context 'with injectable client' do
      it 'uses provided client instead of creating new one' do
        mock_client = instance_double(TapasXq::Client)
        allow(mock_client).to receive(:post).and_return("<mods/>")

        service = described_class.new(core_file, client: mock_client)
        service.store

        expect(mock_client).to have_received(:post)
      end
    end
  end
end
