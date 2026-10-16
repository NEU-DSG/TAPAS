# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Admin::Collections", type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:depositor) { create(:user) }
  let(:project) { create(:project, depositor: depositor) }
  let(:resource) { create(:collection, project: project, depositor: depositor) }
  let(:index_path) { admin_collections_path }
  let(:show_path) { admin_collection_path(resource) }

  before { sign_in admin_user }

  it_behaves_like "an admin controller"

  describe "GET /admin/collections (custom index view)" do
    it "displays the 'All Collections' clear link" do
      get admin_collections_path
      expect(response.body).to include("All Collections")
    end

    it "shows a button for each search filter" do
      get admin_collections_path
      expect(response.body).to include(%(href="#{admin_collections_path(search: "public:")}"))
      expect(response.body).to include(%(href="#{admin_collections_path(search: "private:")}"))
    end
  end

  describe "CRUD pages" do
    let(:edit_path) { edit_admin_collection_path(resource) }
    let(:index_text) { resource.title }
    let(:show_text) { resource.description }
    let(:param_key) { :collection }
    let(:valid_update) { { title: "Renamed Collection" } }
    let(:updated) { -> { resource.reload.title == "Renamed Collection" } }
    let(:invalid_update) { { title: "" } }

    it_behaves_like "admin CRUD pages"
  end

  it "applies the private: search filter" do
    public_collection = create(:collection, title: "Open Letters")
    owner = create(:user)
    private_collection = create(:collection, title: "Sealed Letters", is_public: false, depositor: owner,
                                project: create(:project, is_public: false, depositor: owner))
    get admin_collections_path, params: { search: "private:" }
    expect(response.body).to include(private_collection.title)
    expect(response.body).not_to include(public_collection.title)
  end

  it "edits core files from their own pages, not from the collection form" do
    get edit_admin_collection_path(resource)
    expect(response.body).not_to include("collection[core_file_ids]")
    expect(response.body).not_to include("collection[collection_core_file_ids]")
  end

  it "saves when the image fields are left blank" do
    blank_image = { title: "", description: "", image_url: "", file_format: "", depositor_id: "" }
    patch admin_collection_path(resource), params: { collection: { title: "Renamed", image_file_attributes: blank_image } }
    expect(response).to redirect_to(admin_collection_path(resource))
    expect(resource.reload.title).to eq("Renamed")
  end
end
