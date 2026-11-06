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

    it "gives only the recent: search filter a button, since Public/Private buttons already exist" do
      get admin_projects_path
      expect(response.body).to include(%(href="#{admin_projects_path(search: "recent:")}"))
      expect(response.body).not_to include(%(href="#{admin_projects_path(search: "public:")}"))
      expect(response.body).not_to include(%(href="#{admin_projects_path(search: "private:")}"))
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
      expect(nav_section).not_to include(%(href="#{admin_image_files_path}"))
      expect(nav_section).not_to include(%(href="#{admin_view_packages_path}"))
      # The plain project_members index is restricted, but the scoped review
      # queue (a sub-path) is intentionally linked — see spec below.
      expect(nav_section).not_to include(%(href="#{admin_project_members_path}"))
      expect(nav_section).not_to include(%(href="#{admin_collection_core_files_path}"))
    end

    it "shows the account review queue link" do
      get admin_projects_path
      nav_section = response.body[/(<nav.*?<\/nav>)/m, 1]
      expect(nav_section).to include(%(href="#{review_queue_admin_users_path}"))
    end

    it "shows the invitation links queue link" do
      get admin_projects_path
      nav_section = response.body[/(<nav.*?<\/nav>)/m, 1]
      expect(nav_section).to include(%(href="#{admin_project_invitations_path}"))
    end

    describe "highlighted section" do
      def active_nav_links
        Nokogiri::HTML(response.body).css("nav a.navigation__link--active").map { |link| link.text.strip }
      end

      it "highlights Projects on /admin, a project's page and its edit page" do
        project = create(:project)
        [ admin_root_path, admin_projects_path, admin_project_path(project), edit_admin_project_path(project) ].each do |path|
          get path
          expect(active_nav_links).to eq([ "Projects" ]), "on #{path}"
        end
      end

      it "highlights New Account Review, not Users, on the review queue" do
        get review_queue_admin_users_path
        expect(active_nav_links).to eq([ "New Account Review" ])
      end

      it "highlights Users on a user's page" do
        get admin_user_path(admin_user)
        expect(active_nav_links).to eq([ "Users" ])
      end

      it "highlights Invitation Links on the invitation links page" do
        get admin_project_invitations_path
        expect(active_nav_links).to eq([ "Invitation Links" ])
      end

      it "highlights nothing on sections without a sidebar link" do
        get admin_image_files_path
        expect(active_nav_links).to be_empty
      end
    end
  end

  describe "GET /admin (admin root)" do
    it "routes to projects#index" do
      get admin_root_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "CRUD pages" do
    let(:resource) { create(:project, description: "A project about letters") }
    let(:index_path) { admin_projects_path }
    let(:show_path) { admin_project_path(resource) }
    let(:edit_path) { edit_admin_project_path(resource) }
    let(:index_text) { resource.title }
    let(:show_text) { resource.description }
    let(:param_key) { :project }
    let(:valid_update) { { title: "Renamed Project" } }
    let(:updated) { -> { resource.reload.title == "Renamed Project" } }
    let(:invalid_update) { { title: "" } }

    it_behaves_like "admin CRUD pages"

    it "searches titles" do
      other = create(:project, title: "Unrelated Work")
      get admin_projects_path, params: { search: "letters" }
      expect(response.body).not_to include(other.title)
    end

    it "edits collections, members and users from their own pages, not from the project form" do
      get edit_admin_project_path(resource)
      %w[collection_ids project_member_ids user_ids core_file_ids].each do |field|
        expect(response.body).not_to include("project[#{field}]")
      end
    end

    it "lists collections and members on the show page" do
      collection = create(:collection, project: resource, depositor: resource.depositor)
      get admin_project_path(resource)
      expect(response.body).to include(admin_collection_path(collection))
      expect(response.body).to include(admin_project_member_path(resource.project_members.first))
    end
  end
end
