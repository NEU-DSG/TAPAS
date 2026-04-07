# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Users", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  describe "GET /users/:id" do
    it "is publicly accessible" do
      get user_path(user)
      expect(response).to have_http_status(:ok)
    end

    it "does not require authentication" do
      get user_path(user)
      expect(response).not_to redirect_to(new_user_session_path)
    end
  end

  describe "GET /users/:id/edit" do
    context "when not signed in" do
      it "redirects to sign in" do
        get edit_user_path(user)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in as the correct user" do
      before { sign_in user }

      it "returns ok" do
        get edit_user_path(user)
        expect(response).to have_http_status(:ok)
      end
    end

    context "when signed in as a different user" do
      before { sign_in other_user }

      it "returns forbidden" do
        get edit_user_path(user), as: :json
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "PATCH /users/:id" do
    let(:valid_params) { { user: { name: "Updated Name", bio: "A new bio", institution: "NEU" } } }

    context "when not signed in" do
      it "redirects to sign in" do
        patch user_path(user), params: valid_params
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in as the correct user" do
      before { sign_in user }

      it "updates the user" do
        patch user_path(user), params: valid_params
        user.reload
        expect(user.name).to eq("Updated Name")
        expect(user.bio).to eq("A new bio")
        expect(user.institution).to eq("NEU")
      end

      it "returns ok status" do
        patch user_path(user), params: valid_params
        expect(response).to have_http_status(:ok)
      end

      it "returns the updated user as JSON" do
        patch user_path(user), params: valid_params
        json = JSON.parse(response.body)
        expect(json["name"]).to eq("Updated Name")
      end
    end

    context "when signed in as a different user" do
      before { sign_in other_user }

      it "returns forbidden" do
        patch user_path(user), params: valid_params, as: :json
        expect(response).to have_http_status(:forbidden)
      end

      it "does not update the user" do
        patch user_path(user), params: valid_params, as: :json
        expect(user.reload.name).not_to eq("Updated Name")
      end
    end
  end
end
