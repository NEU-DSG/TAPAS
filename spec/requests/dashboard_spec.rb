# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:owned_project) { create(:project, depositor: user) }
  let(:contributed_project) { create(:project, depositor: other_user) }
  let!(:contributor_membership) do
    create(:project_member, :contributor, project: contributed_project, user: user)
  end
  let(:collection) { create(:collection, project: owned_project, depositor: user) }
  let(:core_file) { create(:core_file, depositor: user, collections: [ collection ]) }

  describe "GET /dashboard" do
    context "when not signed in" do
      it "redirects to sign in" do
        get dashboard_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in" do
      before do
        sign_in user
        owned_project
        contributed_project
        contributor_membership
        collection
        core_file
      end

      it "returns 200" do
        get dashboard_path, as: :json
        expect(response).to have_http_status(:ok)
      end

      it "includes owned projects" do
        get dashboard_path, as: :json
        json = JSON.parse(response.body)
        expect(json["owned_projects"].map { |p| p["id"] }).to include(owned_project.id)
      end

      it "does not include contributed projects in owned_projects" do
        get dashboard_path, as: :json
        json = JSON.parse(response.body)
        expect(json["owned_projects"].map { |p| p["id"] }).not_to include(contributed_project.id)
      end

      it "includes contributed projects" do
        get dashboard_path, as: :json
        json = JSON.parse(response.body)
        expect(json["contributed_projects"].map { |p| p["id"] }).to include(contributed_project.id)
      end

      it "does not include owned projects in contributed_projects" do
        get dashboard_path, as: :json
        json = JSON.parse(response.body)
        expect(json["contributed_projects"].map { |p| p["id"] }).not_to include(owned_project.id)
      end

      it "includes accessible collections" do
        get dashboard_path, as: :json
        json = JSON.parse(response.body)
        expect(json["collections"].map { |c| c["id"] }).to include(collection.id)
      end

      it "includes deposited core files" do
        get dashboard_path, as: :json
        json = JSON.parse(response.body)
        expect(json["core_files"].map { |f| f["id"] }).to include(core_file.id)
      end

      it "does not include core files deposited by others" do
        other_collection = create(:collection, project: contributed_project, depositor: other_user)
        other_core_file = create(:core_file, depositor: other_user, collections: [ other_collection ])
        get dashboard_path, as: :json
        json = JSON.parse(response.body)
        expect(json["core_files"].map { |f| f["id"] }).not_to include(other_core_file.id)
      end
    end
  end
end
