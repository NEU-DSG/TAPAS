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
end
