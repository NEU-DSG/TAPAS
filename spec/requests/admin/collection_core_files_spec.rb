# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Admin::CollectionCoreFiles", type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:depositor) { create(:user) }
  let(:project) { create(:project, depositor: depositor) }
  let(:collection) { create(:collection, project: project, depositor: depositor) }
  let(:core_file) { create(:core_file, depositor: depositor, collections: [ collection ]) }
  let(:resource) { core_file.collection_core_files.first }
  let(:index_path) { admin_collection_core_files_path }
  let(:show_path) { admin_collection_core_file_path(resource) }

  before { sign_in admin_user }

  it_behaves_like "an admin controller"

  describe "CRUD pages" do
    let(:other_collection) { create(:collection, project: project, depositor: depositor) }
    let(:edit_path) { edit_admin_collection_core_file_path(resource) }
    let(:index_text) { collection.title }
    let(:show_text) { core_file.title }
    let(:param_key) { :collection_core_file }
    let(:valid_update) { { collection_id: other_collection.id } }
    let(:updated) { -> { resource.reload.collection == other_collection } }
    let(:invalid_update) { { collection_id: create(:collection).id } }

    it_behaves_like "admin CRUD pages"
  end

  it "has no search box, since there are no text columns to search" do
    get index_path
    expect(response.body).not_to include(%(role="search"))
  end
end
