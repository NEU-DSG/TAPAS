# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Admin::ViewPackages", type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:resource) { create(:view_package) }
  let(:index_path) { admin_view_packages_path }
  let(:show_path) { admin_view_package_path(resource) }

  before { sign_in admin_user }

  it_behaves_like "an admin controller"
end
