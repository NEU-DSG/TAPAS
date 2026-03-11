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

    it "displays search filter help text" do
      get admin_collections_path
      expect(response.body).to include("Search filters: public:, private:")
    end
  end
end
