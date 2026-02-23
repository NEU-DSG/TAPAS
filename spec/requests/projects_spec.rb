# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Projects", type: :request do
  let(:user) { create(:user) }
  let(:project) { create(:project, depositor: user) }

  describe "POST /projects" do
    let(:valid_params) { { project: { title: "New Project", description: "A description", institution: "NEU", is_public: true } } }
    let(:invalid_params) { { project: { title: "" } } }

    context "when not signed in" do
      it "redirects to sign in" do
        post projects_path, params: valid_params
        expect(response).to redirect_to(new_user_session_path)
      end

      it "does not create a project" do
        expect {
          post projects_path, params: valid_params
        }.not_to change(Project, :count)
      end
    end

    context "when signed in" do
      before { sign_in user }

      context "with valid params" do
        it "creates a project" do
          expect {
            post projects_path, params: valid_params
          }.to change(Project, :count).by(1)
        end

        it "returns created status" do
          post projects_path, params: valid_params
          expect(response).to have_http_status(:created)
        end

        it "returns the project as JSON" do
          post projects_path, params: valid_params
          json = JSON.parse(response.body)
          expect(json["title"]).to eq("New Project")
          expect(json["description"]).to eq("A description")
          expect(json["institution"]).to eq("NEU")
          expect(json["is_public"]).to eq(true)
        end

        it "sets the depositor to the current user" do
          post projects_path, params: valid_params
          expect(Project.last.depositor).to eq(user)
        end
      end

      context "with invalid params" do
        it "does not create a project" do
          expect {
            post projects_path, params: invalid_params
          }.not_to change(Project, :count)
        end

        it "returns unprocessable entity status" do
          post projects_path, params: invalid_params
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "returns error messages" do
          post projects_path, params: invalid_params
          json = JSON.parse(response.body)
          expect(json["errors"]).to be_present
        end
      end
    end
  end

  describe "PATCH /projects/:id" do
    let(:update_params) { { project: { title: "Updated Title", description: "Updated description" } } }

    context "when not signed in" do
      it "redirects to sign in" do
        patch project_path(project), params: update_params
        expect(response).to redirect_to(new_user_session_path)
      end

      it "does not update the project" do
        patch project_path(project), params: update_params
        expect(project.reload.title).not_to eq("Updated Title")
      end
    end

    context "when signed in" do
      before { sign_in user }

      context "with valid params" do
        it "updates the project" do
          patch project_path(project), params: update_params
          project.reload
          expect(project.title).to eq("Updated Title")
          expect(project.description).to eq("Updated description")
        end

        it "returns ok status" do
          patch project_path(project), params: update_params
          expect(response).to have_http_status(:ok)
        end

        it "returns the updated project as JSON" do
          patch project_path(project), params: update_params
          json = JSON.parse(response.body)
          expect(json["title"]).to eq("Updated Title")
        end
      end

      context "with invalid params" do
        it "does not update the project" do
          original_title = project.title
          patch project_path(project), params: { project: { title: "" } }
          expect(project.reload.title).to eq(original_title)
        end

        it "returns unprocessable entity status" do
          patch project_path(project), params: { project: { title: "" } }
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "returns error messages" do
          patch project_path(project), params: { project: { title: "" } }
          json = JSON.parse(response.body)
          expect(json["errors"]).to be_present
        end
      end
    end
  end

  describe "DELETE /projects/:id" do
    context "when not signed in" do
      it "redirects to sign in" do
        delete project_path(project)
        expect(response).to redirect_to(new_user_session_path)
      end

      it "does not delete the project" do
        project # force creation
        expect {
          delete project_path(project)
        }.not_to change(Project, :count)
      end
    end

    context "when signed in" do
      before { sign_in user }

      it "deletes the project" do
        project # force creation
        expect {
          delete project_path(project)
        }.to change(Project, :count).by(-1)
      end

      it "returns no content status" do
        delete project_path(project)
        expect(response).to have_http_status(:no_content)
      end
    end
  end
end
