# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Admin::ImageFiles", type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:resource) { create(:image_file) }
  let(:index_path) { admin_image_files_path }
  let(:show_path) { admin_image_file_path(resource) }

  before { sign_in admin_user }

  it_behaves_like "an admin controller"

  describe "CRUD pages" do
    let(:edit_path) { edit_admin_image_file_path(resource) }
    let(:index_text) { resource.title }
    let(:show_text) { resource.image_url }
    let(:param_key) { :image_file }
    let(:valid_update) { { title: "Renamed Image" } }
    let(:updated) { -> { resource.reload.title == "Renamed Image" } }
    let(:invalid_update) { { title: "" } }

    it_behaves_like "admin CRUD pages"
  end

  it "has no New button, since the form can't attach an image to a record" do
    get index_path
    expect(response.body).not_to include(new_admin_image_file_path)
  end
end
