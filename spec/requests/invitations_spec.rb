# frozen_string_literal: true

require "rails_helper"

RSpec::Matchers.define_negated_matcher :not_have_enqueued_mail, :have_enqueued_mail

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

        it "enqueues an owner confirmation request with no admin step" do
          expect {
            post accept_invitation_path(invitation.token)
          }.to have_enqueued_mail(InvitationMailer, :owner_confirmation_request)
            .and not_have_enqueued_mail(AccountReviewMailer, :new_registration)
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

  describe "registering a brand-new TAPAS account from an invitation link" do
    before { invitation } # eager-load so project + its owner member exist before count checks

    let(:signup_params) do
      {
        invitation_token: invitation.token,
        user: { email: "new-invitee@example.com", password: "password123", password_confirmation: "password123" }
      }
    end

    it "creates a blocked account carrying the invitation token and notifies admins" do
      expect {
        post user_registration_path, params: signup_params
      }.to have_enqueued_mail(AccountReviewMailer, :new_registration)

      new_user = User.find_by(email: "new-invitee@example.com")
      expect(new_user).to be_pending_review
      expect(new_user.signup_invitation_token).to eq(invitation.token)
    end

    it "does not sign the registrant in, so they cannot accept before review" do
      post user_registration_path, params: signup_params

      expect {
        post accept_invitation_path(invitation.token)
      }.not_to change(ProjectMember, :count)
      expect(response).to redirect_to(new_user_session_path)
    end

    it "follows the normal acceptance path once an admin approves the account" do
      post user_registration_path, params: signup_params
      new_user = User.find_by(email: "new-invitee@example.com")

      admin = create(:user, :admin)
      sign_in admin
      expect {
        patch approve_account_admin_user_path(new_user)
      }.to have_enqueued_mail(AccountReviewMailer, :account_approved)
      sign_out admin

      sign_in new_user.reload
      expect {
        post accept_invitation_path(invitation.token)
      }.to change(ProjectMember, :count).by(1)
        .and have_enqueued_mail(InvitationMailer, :owner_confirmation_request)

      expect(ProjectMember.last.status).to eq("pending")
      expect(new_user.reload.signup_invitation_token).to be_nil
    end
  end
end
