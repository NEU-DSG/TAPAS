# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "CoreFiles", type: :request do
  let(:user) { create(:user) }
  let(:project) { create(:project, depositor: user) }
  let(:collection) { create(:collection, project: project, depositor: user) }
  let(:core_file) { create(:core_file, depositor: user, collections: [ collection ]) }

  describe "POST /core_files" do
    let(:valid_params) { { core_file: { title: "New Core File", description: "A description", is_public: true, collection_ids: [ collection.id ] } } }
    let(:invalid_params) { { core_file: { title: "" } } }

    context "when not signed in" do
      it "redirects to sign in" do
        post core_files_path, params: valid_params
        expect(response).to redirect_to(new_user_session_path)
      end

      it "does not create a core file" do
        expect {
          post core_files_path, params: valid_params
        }.not_to change(CoreFile, :count)
      end
    end

    context "when signed in" do
      before { sign_in user }

      context "with valid params" do
        it "creates a core file" do
          expect {
            post core_files_path, params: valid_params
          }.to change(CoreFile, :count).by(1)
        end

        it "returns created status" do
          post core_files_path, params: valid_params
          expect(response).to have_http_status(:created)
        end

        it "returns the core file as JSON" do
          post core_files_path, params: valid_params
          json = JSON.parse(response.body)
          expect(json["title"]).to eq("New Core File")
          expect(json["description"]).to eq("A description")
          expect(json["is_public"]).to eq(true)
        end

        it "sets the depositor to the current user" do
          post core_files_path, params: valid_params
          expect(CoreFile.last.depositor).to eq(user)
        end

        it "associates the core file with the specified collections" do
          post core_files_path, params: valid_params
          expect(CoreFile.last.collections).to include(collection)
        end
      end

      context "with invalid params" do
        it "does not create a core file" do
          expect {
            post core_files_path, params: invalid_params
          }.not_to change(CoreFile, :count)
        end

        it "returns unprocessable entity status" do
          post core_files_path, params: invalid_params
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "returns error messages" do
          post core_files_path, params: invalid_params
          json = JSON.parse(response.body)
          expect(json["errors"]).to be_present
        end
      end

      context "with an ography type" do
        let(:ography_params) { { core_file: { title: "Personography File", ography_type: "personography", collection_ids: [ collection.id ] } } }

        it "creates a core file with the ography type" do
          post core_files_path, params: ography_params
          expect(CoreFile.last.ography_type).to eq("personography")
        end
      end

      context "with collections from different projects" do
        let(:other_project) { create(:project, depositor: user) }
        let(:other_collection) { create(:collection, project: other_project, depositor: user) }
        let(:cross_project_params) { { core_file: { title: "Cross Project File", collection_ids: [ collection.id, other_collection.id ] } } }

        it "does not create the core file" do
          expect {
            post core_files_path, params: cross_project_params
          }.not_to change(CoreFile, :count)
        end

        it "returns unprocessable entity status" do
          post core_files_path, params: cross_project_params
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end

  describe "PATCH /core_files/:id" do
    let(:update_params) { { core_file: { title: "Updated Title", description: "Updated description" } } }

    context "when not signed in" do
      it "redirects to sign in" do
        patch core_file_path(core_file), params: update_params
        expect(response).to redirect_to(new_user_session_path)
      end

      it "does not update the core file" do
        patch core_file_path(core_file), params: update_params
        expect(core_file.reload.title).not_to eq("Updated Title")
      end
    end

    context "when signed in" do
      before { sign_in user }

      context "with valid params" do
        it "updates the core file" do
          patch core_file_path(core_file), params: update_params
          core_file.reload
          expect(core_file.title).to eq("Updated Title")
          expect(core_file.description).to eq("Updated description")
        end

        it "returns ok status" do
          patch core_file_path(core_file), params: update_params
          expect(response).to have_http_status(:ok)
        end

        it "returns the updated core file as JSON" do
          patch core_file_path(core_file), params: update_params
          json = JSON.parse(response.body)
          expect(json["title"]).to eq("Updated Title")
        end
      end

      context "with invalid params" do
        it "does not update the core file" do
          original_title = core_file.title
          patch core_file_path(core_file), params: { core_file: { title: "" } }
          expect(core_file.reload.title).to eq(original_title)
        end

        it "returns unprocessable entity status" do
          patch core_file_path(core_file), params: { core_file: { title: "" } }
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "returns error messages" do
          patch core_file_path(core_file), params: { core_file: { title: "" } }
          json = JSON.parse(response.body)
          expect(json["errors"]).to be_present
        end
      end

      context "when updating collection associations" do
        let(:new_collection) { create(:collection, project: project, depositor: user) }

        it "updates the associated collections" do
          patch core_file_path(core_file), params: { core_file: { collection_ids: [ new_collection.id ] } }
          expect(core_file.reload.collections).to eq([ new_collection ])
        end
      end
    end
  end

  describe "DELETE /core_files/:id" do
    context "when not signed in" do
      it "redirects to sign in" do
        delete core_file_path(core_file)
        expect(response).to redirect_to(new_user_session_path)
      end

      it "does not delete the core file" do
        core_file # force creation
        expect {
          delete core_file_path(core_file)
        }.not_to change(CoreFile, :count)
      end
    end

    context "when signed in" do
      before { sign_in user }

      it "deletes the core file" do
        core_file # force creation
        expect {
          delete core_file_path(core_file)
        }.to change(CoreFile, :count).by(-1)
      end

      it "returns no content status" do
        delete core_file_path(core_file)
        expect(response).to have_http_status(:no_content)
      end
    end
  end
end
