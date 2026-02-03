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

  describe "GET /admin/projects (custom index view)" do
    it "displays the 'All Projects' clear filter link" do
      get admin_projects_path
      expect(response.body).to include("All Projects")
    end

    it "displays the Public filter button" do
      get admin_projects_path
      expect(response.body).to include("Public")
      expect(response.body).to include(admin_projects_path(visibility: "public"))
    end

    it "displays the Private filter button" do
      get admin_projects_path
      expect(response.body).to include("Private")
      expect(response.body).to include(admin_projects_path(visibility: "private"))
    end

    it "includes the clear_filters param in All Projects link" do
      get admin_projects_path
      expect(response.body).to include(admin_projects_path(clear_filters: true))
    end

    it "marks a filter button as active when that filter is applied" do
      get admin_projects_path, params: { visibility: "public" }
      get admin_projects_path
      expect(response.body).to match(/filter-btn\s+active/)
    end
  end

  describe "admin navigation partial" do
    it "displays the TAPAS Admin header" do
      get admin_projects_path
      expect(response.body).to include("TAPAS Admin")
    end

    it "displays the Back to App link" do
      get admin_projects_path
      expect(response.body).to include("Back to App")
    end

    it "shows navigation links for allowed resources" do
      get admin_projects_path
      expect(response.body).to include(admin_collections_path)
      expect(response.body).to include(admin_core_files_path)
      expect(response.body).to include(admin_projects_path)
      expect(response.body).to include(admin_users_path)
    end

    it "does not show navigation links for restricted resources" do
      get admin_projects_path
      nav_section = response.body[/(<nav.*?<\/nav>)/m, 1]
      expect(nav_section).not_to include(admin_image_files_path)
      expect(nav_section).not_to include(admin_view_packages_path)
      expect(nav_section).not_to include(admin_project_members_path)
      expect(nav_section).not_to include(admin_collection_core_files_path)
    end
  end

  describe "GET /admin (admin root)" do
    it "routes to projects#index" do
      get admin_root_path
      expect(response).to have_http_status(:success)
    end
  end
end
