# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Collections", type: :request do
  let(:user) { create(:user) }
  let(:project) { create(:project, depositor: user) }
  let(:collection) { create(:collection, depositor: user, project: project) }

  describe "POST /collections" do
    let(:valid_params) { { collection: { title: "New Collection", description: "A description", project_id: project.id, is_public: true } } }
    let(:invalid_params) { { collection: { title: "" } } }

    context "when not signed in" do
      it "redirects to sign in" do
        post collections_path, params: valid_params
        expect(response).to redirect_to(new_user_session_path)
      end

      it "does not create a collection" do
        expect {
          post collections_path, params: valid_params
        }.not_to change(Collection, :count)
      end
    end

    context "when signed in" do
      before { sign_in user }

      context "with valid params" do
        it "creates a collection" do
          expect {
            post collections_path, params: valid_params
          }.to change(Collection, :count).by(1)
        end

        it "returns created status" do
          post collections_path, params: valid_params
          expect(response).to have_http_status(:created)
        end

        it "returns the collection as JSON" do
          post collections_path, params: valid_params
          json = JSON.parse(response.body)
          expect(json["title"]).to eq("New Collection")
          expect(json["description"]).to eq("A description")
          expect(json["project_id"]).to eq(project.id)
          expect(json["is_public"]).to eq(true)
        end

        it "sets the depositor to the current user" do
          post collections_path, params: valid_params
          expect(Collection.last.depositor).to eq(user)
        end
      end

      context "with invalid params" do
        it "does not create a collection" do
          expect {
            post collections_path, params: invalid_params
          }.not_to change(Collection, :count)
        end

        it "returns unprocessable entity status" do
          post collections_path, params: invalid_params
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "returns error messages" do
          post collections_path, params: invalid_params
          json = JSON.parse(response.body)
          expect(json["errors"]).to be_present
        end
      end
    end
  end

  describe "PATCH /collections/:id" do
    let(:update_params) { { collection: { title: "Updated Title", description: "Updated description" } } }

    context "when not signed in" do
      it "redirects to sign in" do
        patch collection_path(collection), params: update_params
        expect(response).to redirect_to(new_user_session_path)
      end

      it "does not update the collection" do
        patch collection_path(collection), params: update_params
        expect(collection.reload.title).not_to eq("Updated Title")
      end
    end

    context "when signed in" do
      before { sign_in user }

      context "with valid params" do
        it "updates the collection" do
          patch collection_path(collection), params: update_params
          collection.reload
          expect(collection.title).to eq("Updated Title")
          expect(collection.description).to eq("Updated description")
        end

        it "returns ok status" do
          patch collection_path(collection), params: update_params
          expect(response).to have_http_status(:ok)
        end

        it "returns the updated collection as JSON" do
          patch collection_path(collection), params: update_params
          json = JSON.parse(response.body)
          expect(json["title"]).to eq("Updated Title")
        end
      end

      context "with invalid params" do
        it "does not update the collection" do
          original_title = collection.title
          patch collection_path(collection), params: { collection: { title: "" } }
          expect(collection.reload.title).to eq(original_title)
        end

        it "returns unprocessable entity status" do
          patch collection_path(collection), params: { collection: { title: "" } }
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "returns error messages" do
          patch collection_path(collection), params: { collection: { title: "" } }
          json = JSON.parse(response.body)
          expect(json["errors"]).to be_present
        end
      end
    end
  end

  describe "DELETE /collections/:id" do
    context "when not signed in" do
      it "redirects to sign in" do
        delete collection_path(collection)
        expect(response).to redirect_to(new_user_session_path)
      end

      it "does not delete the collection" do
        collection # force creation
        expect {
          delete collection_path(collection)
        }.not_to change(Collection, :count)
      end
    end

    context "when signed in" do
      before { sign_in user }

      it "deletes the collection" do
        collection # force creation
        expect {
          delete collection_path(collection)
        }.to change(Collection, :count).by(-1)
      end

      it "returns no content status" do
        delete collection_path(collection)
        expect(response).to have_http_status(:no_content)
      end
    end
  end
end
