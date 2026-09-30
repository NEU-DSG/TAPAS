# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Admin::Users", type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:resource) { create(:user) }
  let(:index_path) { admin_users_path }
  let(:show_path) { admin_user_path(resource) }

  before { sign_in admin_user }

  it_behaves_like "an admin controller"

  describe "GET /admin/users/review_queue" do
    let!(:pending_user) { create(:user, :pending_review) }
    let!(:active_user)  { create(:user) }

    it "returns ok" do
      get review_queue_admin_users_path
      expect(response).to have_http_status(:ok)
    end

    it "shows accounts pending review" do
      get review_queue_admin_users_path
      expect(response.body).to include(pending_user.email)
    end

    it "excludes active accounts" do
      get review_queue_admin_users_path
      expect(response.body).not_to include(active_user.email)
    end

    it "labels direct sign-ups that carried no invitation" do
      get review_queue_admin_users_path
      expect(response.body).to include("Direct sign-up")
    end

    context "when the signup carried a usable invitation token" do
      let(:project)    { create(:project) }
      let(:invitation) { create(:project_invitation, project: project) }
      let!(:pending_user) { create(:user, :pending_review, signup_invitation_token: invitation.token) }

      it "shows the project the user was invited to" do
        get review_queue_admin_users_path
        expect(response.body).to include(project.title)
      end
    end

    context "when not signed in as admin" do
      before { sign_out admin_user; sign_in create(:user) }

      it "redirects away from admin" do
        get review_queue_admin_users_path
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "PATCH /admin/users/:id/approve_account" do
    let!(:pending_user) { create(:user, :pending_review) }

    it "activates the account" do
      patch approve_account_admin_user_path(pending_user)
      expect(pending_user.reload).to be_active
    end

    it "enqueues an approval email to the user" do
      expect {
        patch approve_account_admin_user_path(pending_user)
      }.to have_enqueued_mail(AccountReviewMailer, :account_approved)
    end

    it "redirects back to the queue with a notice" do
      patch approve_account_admin_user_path(pending_user)
      expect(response).to redirect_to(review_queue_admin_users_path)
      expect(flash[:notice]).to be_present
    end

    it "returns not found for an account that is not pending" do
      patch approve_account_admin_user_path(create(:user))
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /admin/users/:id/reject_account" do
    let!(:pending_user) { create(:user, :pending_review) }

    it "deletes the account" do
      expect {
        delete reject_account_admin_user_path(pending_user)
      }.to change(User, :count).by(-1)
      expect(User.exists?(pending_user.id)).to be(false)
    end

    it "sends the registrant nothing — rejection is silent" do
      expect {
        delete reject_account_admin_user_path(pending_user)
      }.not_to have_enqueued_mail
    end

    it "redirects back to the queue with a notice" do
      delete reject_account_admin_user_path(pending_user)
      expect(response).to redirect_to(review_queue_admin_users_path)
      expect(flash[:notice]).to be_present
    end

    it "returns not found for an account that is not pending" do
      delete reject_account_admin_user_path(create(:user))
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /admin/users/bulk_approve_accounts" do
    let!(:pending_users) { create_list(:user, 2, :pending_review) }
    let!(:untouched_user) { create(:user, :pending_review) }

    it "activates every selected account" do
      patch bulk_approve_accounts_admin_users_path, params: { user_ids: pending_users.map(&:id) }
      expect(pending_users.map { |u| u.reload.account_status }).to all(eq("active"))
    end

    it "leaves accounts that were not selected untouched" do
      patch bulk_approve_accounts_admin_users_path, params: { user_ids: pending_users.map(&:id) }
      expect(untouched_user.reload).to be_pending_review
    end

    it "enqueues an approval email for each selected account" do
      expect {
        patch bulk_approve_accounts_admin_users_path, params: { user_ids: pending_users.map(&:id) }
      }.to have_enqueued_mail(AccountReviewMailer, :account_approved).twice
    end

    it "redirects back to the queue with a notice" do
      patch bulk_approve_accounts_admin_users_path, params: { user_ids: pending_users.map(&:id) }
      expect(response).to redirect_to(review_queue_admin_users_path)
      expect(flash[:notice]).to be_present
    end

    it "redirects with an alert when nothing is selected" do
      patch bulk_approve_accounts_admin_users_path, params: { user_ids: [] }
      expect(response).to redirect_to(review_queue_admin_users_path)
      expect(flash[:alert]).to be_present
    end
  end

  describe "DELETE /admin/users/bulk_reject_accounts" do
    let!(:pending_users) { create_list(:user, 2, :pending_review) }
    let!(:untouched_user) { create(:user, :pending_review) }

    it "deletes every selected account" do
      expect {
        delete bulk_reject_accounts_admin_users_path, params: { user_ids: pending_users.map(&:id) }
      }.to change(User, :count).by(-2)
    end

    it "leaves accounts that were not selected untouched" do
      delete bulk_reject_accounts_admin_users_path, params: { user_ids: pending_users.map(&:id) }
      expect(User.exists?(untouched_user.id)).to be(true)
    end

    it "sends the registrants nothing — rejection is silent" do
      expect {
        delete bulk_reject_accounts_admin_users_path, params: { user_ids: pending_users.map(&:id) }
      }.not_to have_enqueued_mail
    end

    it "redirects with an alert when nothing is selected" do
      delete bulk_reject_accounts_admin_users_path, params: { user_ids: [] }
      expect(response).to redirect_to(review_queue_admin_users_path)
      expect(flash[:alert]).to be_present
    end
  end
end
