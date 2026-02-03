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

  describe "GET /admin/core_files/:id (custom show view)" do
    context "when processing has failed with an error" do
      let(:failed_core_file) do
        create(:core_file,
          depositor: depositor,
          collections: [ collection ],
          processing_status: "failed",
          processing_error: "Connection timeout to TAPAS-XQ server"
        )
      end

      it "displays the Retry Processing button" do
        get admin_core_file_path(failed_core_file)
        expect(response.body).to include("Retry Processing")
      end

      it "includes turbo confirm dialog text" do
        get admin_core_file_path(failed_core_file)
        expect(response.body).to include("Re-submit this file to TAPAS-XQ?")
      end

      it "renders the retry processing form pointing to the correct path" do
        get admin_core_file_path(failed_core_file)
        expect(response.body).to include(retry_processing_admin_core_file_path(failed_core_file))
      end

      it "displays the Processing Error heading" do
        get admin_core_file_path(failed_core_file)
        expect(response.body).to include("Processing Error")
      end

      it "displays the error message" do
        get admin_core_file_path(failed_core_file)
        expect(response.body).to include("Connection timeout to TAPAS-XQ server")
      end
    end

    context "when processing is completed" do
      let(:completed_core_file) do
        create(:core_file,
          depositor: depositor,
          collections: [ collection ],
          processing_status: "completed"
        )
      end

      it "does not display the Retry Processing button" do
        get admin_core_file_path(completed_core_file)
        expect(response.body).not_to include("Retry Processing")
      end

      it "does not display the Processing Error section" do
        get admin_core_file_path(completed_core_file)
        expect(response.body).not_to include("Processing Error")
      end
    end

    context "when processing failed but no error message present" do
      let(:failed_no_error) do
        create(:core_file,
          depositor: depositor,
          collections: [ collection ],
          processing_status: "failed",
          processing_error: nil
        )
      end

      it "shows the retry button but not the error section" do
        get admin_core_file_path(failed_no_error)
        expect(response.body).to include("Retry Processing")
        expect(response.body).not_to include("Processing Error")
      end
    end

    it "always displays the Edit button" do
      get admin_core_file_path(resource)
      expect(response.body).to include("Edit")
    end
  end

  describe "GET /admin/core_files (custom index view)" do
    it "displays the 'All Files' clear link" do
      get admin_core_files_path
      expect(response.body).to include("All Files")
    end

    it "displays search filter help text" do
      get admin_core_files_path
      expect(response.body).to include("Search filters: public:, private:, ography:")
    end
  end

  describe "admin flash messages" do
    let(:failed_core_file) do
      create(:core_file,
        depositor: depositor,
        collections: [ collection ],
        processing_status: "failed",
        processing_error: "Error"
      )
    end

    it "renders flash notice after successful retry" do
      post retry_processing_admin_core_file_path(failed_core_file)
      follow_redirect!
      expect(response.body).to include("flash-notice")
      expect(response.body).to include("re-queued")
    end

    it "renders flash error for non-retryable files" do
      completed_file = create(:core_file,
        depositor: depositor,
        collections: [ collection ],
        processing_status: "completed"
      )
      post retry_processing_admin_core_file_path(completed_file)
      follow_redirect!
      expect(response.body).to include("flash-error")
      expect(response.body).to include("Cannot retry")
    end
  end
end
