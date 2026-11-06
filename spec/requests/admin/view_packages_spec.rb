# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Admin::ViewPackages", type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:resource) { create(:view_package) }
  let(:index_path) { admin_view_packages_path }
  let(:show_path) { admin_view_package_path(resource) }

  before { sign_in admin_user }

  it_behaves_like "an admin controller"

  describe "CRUD pages" do
    let(:edit_path) { edit_admin_view_package_path(resource) }
    let(:index_text) { admin_view_package_path(resource) }
    let(:show_text) { resource.human_name }
    let(:param_key) { :view_package }
    let(:valid_update) { { human_name: "Renamed Package" } }
    let(:updated) { -> { resource.reload.human_name == "Renamed Package" } }
    let(:invalid_update) { nil }

    it_behaves_like "admin CRUD pages"
  end
end
