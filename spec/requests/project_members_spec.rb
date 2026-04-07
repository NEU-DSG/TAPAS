# frozen_string_literal: true

require "rails_helper"

RSpec.describe "ProjectMembers", type: :request do
  let(:owner) { create(:user) }
  let(:project) { create(:project, depositor: owner) }
  let(:other_user) { create(:user) }
  let(:contributor) { create(:user) }
  let!(:contributor_member) { create(:project_member, project: project, user: contributor, role: "contributor") }

  describe "POST /projects/:project_id/project_members" do
    let(:valid_params) { { project_member: { user_id: other_user.id, role: "contributor" } } }

    context "when not signed in" do
      it "redirects to sign in" do
        post project_project_members_path(project), params: valid_params
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in as the project owner" do
      before { sign_in owner }

      it "adds the user to the project" do
        expect {
          post project_project_members_path(project), params: valid_params
        }.to change(ProjectMember, :count).by(1)
      end

      it "returns created status" do
        post project_project_members_path(project), params: valid_params
        expect(response).to have_http_status(:created)
      end

      it "assigns the specified role" do
        post project_project_members_path(project), params: valid_params
        expect(ProjectMember.last.role).to eq("contributor")
      end

      context "with an invalid role" do
        it "returns unprocessable entity" do
          post project_project_members_path(project),
            params: { project_member: { user_id: other_user.id, role: "admin" } }
          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end

    context "when signed in as a non-owner" do
      before { sign_in contributor }

      it "returns forbidden" do
        post project_project_members_path(project), params: valid_params, as: :json
        expect(response).to have_http_status(:forbidden)
      end

      it "does not add a member" do
        expect {
          post project_project_members_path(project), params: valid_params, as: :json
        }.not_to change(ProjectMember, :count)
      end
    end
  end

  describe "PATCH /projects/:project_id/project_members/:id" do
    let(:update_params) { { project_member: { role: "owner" } } }

    context "when not signed in" do
      it "redirects to sign in" do
        patch project_project_member_path(project, contributor_member), params: update_params
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in as the project owner" do
      before { sign_in owner }

      it "updates the member's role" do
        patch project_project_member_path(project, contributor_member), params: update_params
        expect(contributor_member.reload.role).to eq("owner")
      end

      it "returns ok status" do
        patch project_project_member_path(project, contributor_member), params: update_params
        expect(response).to have_http_status(:ok)
      end
    end

    context "when signed in as a non-owner" do
      before { sign_in contributor }

      it "returns forbidden" do
        patch project_project_member_path(project, contributor_member), params: update_params, as: :json
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "DELETE /projects/:project_id/project_members/:id" do
    context "when not signed in" do
      it "redirects to sign in" do
        delete project_project_member_path(project, contributor_member)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in as the project owner" do
      before { sign_in owner }

      it "removes the member" do
        expect {
          delete project_project_member_path(project, contributor_member)
        }.to change(ProjectMember, :count).by(-1)
      end

      it "returns no content status" do
        delete project_project_member_path(project, contributor_member)
        expect(response).to have_http_status(:no_content)
      end

      context "when attempting to remove the last owner" do
        let!(:owner_member) { project.project_members.find_by(user: owner, role: "owner") }

        it "returns unprocessable entity" do
          delete project_project_member_path(project, owner_member), as: :json
          expect(response).to have_http_status(:unprocessable_content)
        end

        it "does not remove the member" do
          expect {
            delete project_project_member_path(project, owner_member), as: :json
          }.not_to change(ProjectMember, :count)
        end
      end
    end

    context "when signed in as a non-owner" do
      before { sign_in contributor }

      it "returns forbidden" do
        delete project_project_member_path(project, contributor_member), as: :json
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
