# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Users::Registrations", type: :request do
  let(:valid_params) do
    {
      user: {
        email: "new-signup@example.com",
        password: "password123",
        password_confirmation: "password123"
      }
    }
  end

  describe "POST /users (sign up)" do
    it "creates a pending_review account when the honeypot field is left blank" do
      expect {
        post user_registration_path, params: valid_params
      }.to change(User, :count).by(1)
      expect(User.find_by(email: "new-signup@example.com")).to be_pending_review
    end

    it "notifies admins when the honeypot field is left blank" do
      expect {
        post user_registration_path, params: valid_params
      }.to have_enqueued_mail(AccountReviewMailer, :new_registration)
    end

    context "when the honeypot field is filled in" do
      let(:spam_params) { valid_params.deep_merge(user: { website: "http://spam.example.com" }) }

      it "does not create a user account" do
        expect {
          post user_registration_path, params: spam_params
        }.not_to change(User, :count)
      end

      it "does not notify admins" do
        expect {
          post user_registration_path, params: spam_params
        }.not_to have_enqueued_mail(AccountReviewMailer, :new_registration)
      end
    end
  end
end
