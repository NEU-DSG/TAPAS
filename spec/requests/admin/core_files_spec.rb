# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Admin::CoreFiles", type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:depositor) { create(:user) }
  let(:project) { create(:project, depositor: depositor) }
  let(:collection) { create(:collection, project: project, depositor: depositor) }
  let(:resource) { create(:core_file, depositor: depositor, collections: [ collection ]) }
  let(:index_path) { admin_core_files_path }
  let(:show_path) { admin_core_file_path(resource) }

  before do
    sign_in admin_user
  end

  it_behaves_like "an admin controller"

  describe "POST /admin/core_files/:id/retry_processing" do
    context 'with failed processing' do
      let(:core_file) do
        create(:core_file,
          depositor: depositor,
          collections: [ collection ],
          processing_status: 'failed',
          processing_error: 'Connection error'
        )
      end

      it 'retries processing' do
        expect {
          post retry_processing_admin_core_file_path(core_file)
        }.to have_enqueued_job(ProcessTeiFileJob).with(core_file.id)
      end

      it 'resets processing status to pending' do
        post retry_processing_admin_core_file_path(core_file)
        expect(core_file.reload.processing_status).to eq('pending')
      end

      it 'clears processing error' do
        post retry_processing_admin_core_file_path(core_file)
        expect(core_file.reload.processing_error).to be_nil
      end

      it 'redirects to show page' do
        post retry_processing_admin_core_file_path(core_file)
        expect(response).to redirect_to(admin_core_file_path(core_file))
      end

      it 'sets success flash message' do
        post retry_processing_admin_core_file_path(core_file)
        expect(flash[:notice]).to include('re-queued')
      end
    end

    context 'with non-failed processing' do
      let(:core_file) do
        create(:core_file,
          depositor: depositor,
          collections: [ collection ],
          processing_status: 'completed'
        )
      end

      it 'does not retry processing' do
        expect {
          post retry_processing_admin_core_file_path(core_file)
        }.not_to have_enqueued_job(ProcessTeiFileJob)
      end

      it 'redirects to show page' do
        post retry_processing_admin_core_file_path(core_file)
        expect(response).to redirect_to(admin_core_file_path(core_file))
      end

      it 'sets error flash message' do
        post retry_processing_admin_core_file_path(core_file)
        expect(flash[:error]).to include('Cannot retry')
      end
    end

    context 'when not signed in as admin' do
      before { sign_out :user }

      let(:core_file) do
        create(:core_file,
          depositor: depositor,
          collections: [ collection ],
          processing_status: 'failed'
        )
      end

      it 'redirects to sign in page' do
        post retry_processing_admin_core_file_path(core_file)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
