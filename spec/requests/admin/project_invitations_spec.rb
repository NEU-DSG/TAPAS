# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::ProjectInvitations", type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:project) { create(:project) }
  let!(:active_invitation)  { create(:project_invitation, project: project) }
  let!(:expired_invitation) { create(:project_invitation, :expired, project: project) }
  let!(:revoked_invitation) { create(:project_invitation, :revoked, project: project) }

  before { sign_in admin_user }

  describe "GET /admin/project_invitations" do
    it "returns ok" do
      get admin_project_invitations_path
      expect(response).to have_http_status(:ok)
    end

    it "shows active invitation links" do
      get admin_project_invitations_path
      expect(response.body).to include(invitation_url(active_invitation.token))
    end

    it "excludes expired invitation links" do
      get admin_project_invitations_path
      expect(response.body).not_to include(invitation_url(expired_invitation.token))
    end

    it "excludes revoked invitation links" do
      get admin_project_invitations_path
      expect(response.body).not_to include(invitation_url(revoked_invitation.token))
    end

    context "when not signed in" do
      before { sign_out admin_user }

      it "redirects to sign in" do
        get admin_project_invitations_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in as a non-admin user" do
      before { sign_out admin_user; sign_in create(:user) }

      it "redirects with access denied" do
        get admin_project_invitations_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Access denied.")
      end
    end
  end

  describe "PATCH /admin/project_invitations/:id/revoke" do
    it "sets revoked_at" do
      patch revoke_admin_project_invitation_path(active_invitation)
      expect(active_invitation.reload.revoked_at).to be_present
    end

    it "redirects to the index with a notice" do
      patch revoke_admin_project_invitation_path(active_invitation)
      expect(response).to redirect_to(admin_project_invitations_path)
      expect(flash[:notice]).to be_present
    end

    it "removes the link from the active list" do
      patch revoke_admin_project_invitation_path(active_invitation)
      get admin_project_invitations_path
      expect(response.body).not_to include(invitation_url(active_invitation.token))
    end

    context "when not signed in as admin" do
      before { sign_out admin_user; sign_in create(:user) }

      it "redirects away from admin" do
        patch revoke_admin_project_invitation_path(active_invitation)
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
