# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Invitations", type: :request do
  let(:owner) { create(:user) }
  let(:project) { create(:project, depositor: owner) }
  let(:invitation) { create(:project_invitation, project: project, creator: owner) }
  let(:user) { create(:user) }

  describe "GET /invitations/:token" do
    context "with a valid (usable) token" do
      it "returns ok" do
        get invitation_path(invitation.token)
        expect(response).to have_http_status(:ok)
      end

      it "shows the project name" do
        get invitation_path(invitation.token)
        expect(response.body).to include(project.title)
      end

      it "shows the creator name or email" do
        get invitation_path(invitation.token)
        expect(response.body).to include(owner.name || owner.email)
      end
    end

    context "with an expired token" do
      let(:invitation) { create(:project_invitation, :expired, project: project, creator: owner) }

      it "returns ok" do
        get invitation_path(invitation.token)
        expect(response).to have_http_status(:ok)
      end

      it "shows an expired message" do
        get invitation_path(invitation.token)
        expect(response.body).to include("expired")
      end

      it "does not show the accept button" do
        get invitation_path(invitation.token)
        expect(response.body).not_to include("Accept Invitation")
      end
    end

    context "with a revoked token" do
      let(:invitation) { create(:project_invitation, :revoked, project: project, creator: owner) }

      it "returns ok" do
        get invitation_path(invitation.token)
        expect(response).to have_http_status(:ok)
      end

      it "shows a revoked message distinct from expired" do
        get invitation_path(invitation.token)
        expect(response.body).to include("revoked")
        expect(response.body).not_to include("expired")
      end

      it "does not show the accept button" do
        get invitation_path(invitation.token)
        expect(response.body).not_to include("Accept Invitation")
      end
    end

    context "with an invalid token" do
      it "redirects to root with an alert" do
        get invitation_path("nonexistent-token")
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "POST /invitations/:token/accept" do
    before { invitation } # eager-load so project + its owner member exist before count checks

    context "when not signed in" do
      it "redirects to sign in" do
        post accept_invitation_path(invitation.token)
        expect(response).to redirect_to(new_user_session_path)
      end

      it "does not create a project member" do
        expect {
          post accept_invitation_path(invitation.token)
        }.not_to change(ProjectMember, :count)
      end
    end

    context "when signed in" do
      before { sign_in user }

      context "with a valid token" do
        it "creates a pending project member" do
          expect {
            post accept_invitation_path(invitation.token)
          }.to change(ProjectMember, :count).by(1)
        end

        it "sets member status to pending" do
          post accept_invitation_path(invitation.token)
          expect(ProjectMember.last.status).to eq("pending")
        end

        it "enqueues an admin vetting notification" do
          expect {
            post accept_invitation_path(invitation.token)
          }.to have_enqueued_mail(InvitationMailer, :admin_vetting_notification)
        end

        it "redirects with a notice" do
          post accept_invitation_path(invitation.token)
          expect(response).to redirect_to(root_path)
          expect(flash[:notice]).to be_present
        end
      end

      context "when already a member of the project" do
        before { create(:project_member, project: project, user: user) }

        it "does not create a duplicate member" do
          expect {
            post accept_invitation_path(invitation.token)
          }.not_to change(ProjectMember, :count)
        end

        it "redirects with a notice" do
          post accept_invitation_path(invitation.token)
          expect(response).to redirect_to(root_path)
          expect(flash[:notice]).to be_present
        end
      end

      context "with an expired token" do
        let!(:invitation) { create(:project_invitation, :expired, project: project, creator: owner) }

        it "does not create a project member" do
          expect {
            post accept_invitation_path(invitation.token)
          }.not_to change(ProjectMember, :count)
        end

        it "redirects with an alert" do
          post accept_invitation_path(invitation.token)
          expect(response).to redirect_to(root_path)
          expect(flash[:alert]).to be_present
        end
      end

      context "with a revoked token" do
        let!(:invitation) { create(:project_invitation, :revoked, project: project, creator: owner) }

        it "does not create a project member" do
          expect {
            post accept_invitation_path(invitation.token)
          }.not_to change(ProjectMember, :count)
        end

        it "redirects with an alert" do
          post accept_invitation_path(invitation.token)
          expect(response).to redirect_to(root_path)
          expect(flash[:alert]).to be_present
        end
      end
    end
  end
end
