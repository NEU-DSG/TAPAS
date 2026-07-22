# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Account-level registration vetting", type: :request do
  describe "POST /users/sign_in" do
    context "when the account is pending_review" do
      let!(:user) { create(:user, :pending_review, password: "password123") }

      it "does not sign the user in" do
        post user_session_path, params: { user: { email: user.email, password: "password123" } }
        expect(response).to redirect_to(new_user_session_path)
      end

      it "explains the account is awaiting admin review" do
        post user_session_path, params: { user: { email: user.email, password: "password123" } }
        follow_redirect!
        expect(response.body).to include("awaiting admin review")
      end
    end

    context "when the account is active" do
      let!(:user) { create(:user, password: "password123") }

      it "signs the user in" do
        post user_session_path, params: { user: { email: user.email, password: "password123" } }
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "POST /users (registration)" do
    it "creates the account as pending_review, not active" do
      post user_registration_path, params: {
        user: { email: "brand-new@example.com", password: "password123", password_confirmation: "password123" }
      }
      expect(User.find_by(email: "brand-new@example.com")).to be_pending_review
    end

    it "does not sign the new user in" do
      post user_registration_path, params: {
        user: { email: "brand-new@example.com", password: "password123", password_confirmation: "password123" }
      }
      expect(response).to redirect_to(root_path)
      get edit_user_registration_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "notifies admins" do
      expect {
        post user_registration_path, params: {
          user: { email: "brand-new@example.com", password: "password123", password_confirmation: "password123" }
        }
      }.to have_enqueued_mail(AccountReviewMailer, :new_registration)
    end
  end
end
