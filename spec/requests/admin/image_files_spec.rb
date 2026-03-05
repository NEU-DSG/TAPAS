# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Admin::ImageFiles", type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:resource) { create(:image_file) }
  let(:index_path) { admin_image_files_path }
  let(:show_path) { admin_image_file_path(resource) }

  before { sign_in admin_user }

  it_behaves_like "an admin controller"
end
