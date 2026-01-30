# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Admin::Projects", type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:depositor) { create(:user) }
  let(:resource) { create(:project, depositor: depositor) }
  let(:index_path) { admin_projects_path }
  let(:show_path) { admin_project_path(resource) }

  before { sign_in admin_user }

  it_behaves_like "an admin controller"

  describe "GET /admin/projects (visibility filtering)" do
    let!(:public_project) { create(:project, depositor: depositor, is_public: true, title: "Public Project") }
    let!(:private_project) { create(:project, depositor: depositor, is_public: false, title: "Private Project") }

    it "shows all projects by default" do
      get admin_projects_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Public Project")
      expect(response.body).to include("Private Project")
    end

    it "filters to public projects when visibility=public" do
      get admin_projects_path, params: { visibility: "public" }
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Public Project")
      expect(response.body).not_to include("Private Project")
    end

    it "filters to private projects when visibility=private" do
      get admin_projects_path, params: { visibility: "private" }
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Private Project")
      expect(response.body).not_to include("Public Project")
    end

    it "persists filter in session across requests" do
      get admin_projects_path, params: { visibility: "public" }
      get admin_projects_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Public Project")
      expect(response.body).not_to include("Private Project")
    end

    it "clears filter when clear_filters is present" do
      get admin_projects_path, params: { visibility: "public" }
      get admin_projects_path, params: { clear_filters: true }
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Public Project")
      expect(response.body).to include("Private Project")
    end
  end

  describe "GET /admin (admin root)" do
    it "routes to projects#index" do
      get admin_root_path
      expect(response).to have_http_status(:success)
    end
  end
end
