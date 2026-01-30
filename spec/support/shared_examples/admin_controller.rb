# frozen_string_literal: true

RSpec.shared_examples "an admin controller" do
  describe "authentication" do
    context "when not signed in" do
      before { sign_out :user }

      it "redirects index to sign in" do
        get index_path
        expect(response).to redirect_to(new_user_session_path)
      end

      it "redirects show to sign in" do
        get show_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "authorization" do
    context "when signed in as a non-admin user" do
      let(:regular_user) { create(:user) }

      before do
        sign_out :user
        sign_in regular_user
      end

      it "redirects index with access denied" do
        get index_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Access denied.")
      end

      it "redirects show with access denied" do
        get show_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Access denied.")
      end
    end
  end

  describe "admin access" do
    it "returns success for index" do
      get index_path
      expect(response).to have_http_status(:success)
    end

    it "returns success for show" do
      get show_path
      expect(response).to have_http_status(:success)
    end
  end
end
