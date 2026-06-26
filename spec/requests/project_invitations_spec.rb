# frozen_string_literal: true

require "rails_helper"

RSpec.describe "ProjectInvitations", type: :request do
  let(:owner) { create(:user) }
  let(:project) { create(:project, depositor: owner) }
  let(:other_user) { create(:user) }

  describe "POST /projects/:project_id/project_invitations" do
    context "when not signed in" do
      it "redirects to sign in" do
        post project_project_invitations_path(project)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in as the project owner" do
      before { sign_in owner }

      it "creates an invitation" do
        expect {
          post project_project_invitations_path(project), as: :json
        }.to change(ProjectInvitation, :count).by(1)
      end

      it "returns created status with token and url" do
        post project_project_invitations_path(project), as: :json
        expect(response).to have_http_status(:created)
        body = JSON.parse(response.body)
        expect(body["token"]).to be_present
        expect(body["url"]).to include("/invitations/")
      end
    end

    context "when signed in as a non-owner" do
      before { sign_in other_user }

      it "returns forbidden" do
        post project_project_invitations_path(project), as: :json
        expect(response).to have_http_status(:forbidden)
      end

      it "does not create an invitation" do
        expect {
          post project_project_invitations_path(project), as: :json
        }.not_to change(ProjectInvitation, :count)
      end
    end
  end

  describe "DELETE /projects/:project_id/project_invitations/:id" do
    let!(:invitation) { create(:project_invitation, project: project, creator: owner) }

    context "when not signed in" do
      it "redirects to sign in" do
        delete project_project_invitation_path(project, invitation)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in as the project owner" do
      before { sign_in owner }

      it "revokes the invitation" do
        delete project_project_invitation_path(project, invitation), as: :json
        expect(invitation.reload.revoked_at).to be_present
      end

      it "returns no content" do
        delete project_project_invitation_path(project, invitation), as: :json
        expect(response).to have_http_status(:no_content)
      end

      it "makes the invitation unusable" do
        delete project_project_invitation_path(project, invitation), as: :json
        expect(invitation.reload).not_to be_usable
      end
    end

    context "when signed in as a non-owner" do
      before { sign_in other_user }

      it "returns forbidden" do
        delete project_project_invitation_path(project, invitation), as: :json
        expect(response).to have_http_status(:forbidden)
      end

      it "does not revoke the invitation" do
        delete project_project_invitation_path(project, invitation), as: :json
        expect(invitation.reload.revoked_at).to be_nil
      end
    end
  end
end
