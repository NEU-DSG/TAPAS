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
end
