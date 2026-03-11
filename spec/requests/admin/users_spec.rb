# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Admin::Users", type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:resource) { create(:user) }
  let(:index_path) { admin_users_path }
  let(:show_path) { admin_user_path(resource) }

  before { sign_in admin_user }

  it_behaves_like "an admin controller"
end
