# frozen_string_literal: true

require "rails_helper"

RSpec.describe "CollectionCoreFiles", type: :request do
  let(:owner) { create(:user) }
  let(:non_member) { create(:user) }
  let(:project) { create(:project, depositor: owner) }
  let(:collection) { create(:collection, project: project, depositor: owner) }
  let(:core_file) { create(:core_file, depositor: owner, collections: [ collection ]) }

  describe "POST /collections/:collection_id/collection_core_files" do
    let(:other_collection) { create(:collection, project: project, depositor: owner) }

    context "when not signed in" do
      it "redirects to sign in" do
        post collection_collection_core_files_path(other_collection), params: { core_file_id: core_file.id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "as a project member" do
      before { core_file; sign_in owner }

      it "creates the association" do
        expect {
          post collection_collection_core_files_path(other_collection),
               params: { core_file_id: core_file.id }, as: :json
        }.to change(CollectionCoreFile, :count).by(1)
      end

      it "returns created status" do
        post collection_collection_core_files_path(other_collection),
             params: { core_file_id: core_file.id }, as: :json
        expect(response).to have_http_status(:created)
      end
    end

    context "as a non-member" do
      before { core_file; sign_in non_member }

      it "returns forbidden" do
        post collection_collection_core_files_path(collection),
             params: { core_file_id: core_file.id }, as: :json
        expect(response).to have_http_status(:forbidden)
      end

      it "does not create the association" do
        expect {
          post collection_collection_core_files_path(collection),
               params: { core_file_id: core_file.id }, as: :json
        }.not_to change(CollectionCoreFile, :count)
      end
    end

    context "with a core file from a different project" do
      let(:other_project) { create(:project, depositor: owner) }
      let(:other_project_collection) { create(:collection, project: other_project, depositor: owner) }
      let(:other_project_core_file) { create(:core_file, depositor: owner, collections: [ other_project_collection ]) }

      before { other_project_core_file; sign_in owner }

      it "returns unprocessable entity" do
        post collection_collection_core_files_path(collection),
             params: { core_file_id: other_project_core_file.id }, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns an error message" do
        post collection_collection_core_files_path(collection),
             params: { core_file_id: other_project_core_file.id }, as: :json
        expect(JSON.parse(response.body)["errors"]).to be_present
      end

      it "does not create the association" do
        expect {
          post collection_collection_core_files_path(collection),
               params: { core_file_id: other_project_core_file.id }, as: :json
        }.not_to change(CollectionCoreFile, :count)
      end
    end
  end

  describe "DELETE /collections/:collection_id/collection_core_files/:id" do
    let(:association) { CollectionCoreFile.find_by!(collection: collection, core_file: core_file) }

    before { core_file } # ensure core_file (and its association) is created

    context "when not signed in" do
      it "redirects to sign in" do
        delete collection_collection_core_file_path(collection, association)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "as a project member" do
      before { sign_in owner }

      it "destroys the association" do
        expect {
          delete collection_collection_core_file_path(collection, association), as: :json
        }.to change(CollectionCoreFile, :count).by(-1)
      end

      it "returns no content status" do
        delete collection_collection_core_file_path(collection, association), as: :json
        expect(response).to have_http_status(:no_content)
      end
    end

    context "as a non-member" do
      before { sign_in non_member }

      it "returns forbidden" do
        delete collection_collection_core_file_path(collection, association), as: :json
        expect(response).to have_http_status(:forbidden)
      end

      it "does not destroy the association" do
        expect {
          delete collection_collection_core_file_path(collection, association), as: :json
        }.not_to change(CollectionCoreFile, :count)
      end
    end
  end
end
