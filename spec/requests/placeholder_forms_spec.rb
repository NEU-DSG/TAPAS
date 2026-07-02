# frozen_string_literal: true

require "rails_helper"

# Smoke coverage for the placeholder HTML pages that exist so features are
# manually testable in the browser until the designed frontend replaces them.
# Delete this file alongside those views when that happens.
RSpec.describe "Placeholder HTML pages", type: :request do
  let(:user) { create(:user) }
  let(:project) { create(:project, depositor: user) }
  let(:collection) { create(:collection, project: project, depositor: user) }
  let(:core_file) { create(:core_file, depositor: user, collections: [ collection ]) }

  before { sign_in user }

  it "renders the new project form" do
    get new_project_path
    expect(response).to have_http_status(:ok)
  end

  it "renders the edit project form" do
    get edit_project_path(project)
    expect(response).to have_http_status(:ok)
  end

  it "renders the new collection form" do
    get new_collection_path(project_id: project.id)
    expect(response).to have_http_status(:ok)
  end

  it "renders the edit collection form" do
    get edit_collection_path(collection)
    expect(response).to have_http_status(:ok)
  end

  it "renders the new core file form" do
    get new_core_file_path(collection_id: collection.id)
    expect(response).to have_http_status(:ok)
  end

  it "renders the edit core file form" do
    get edit_core_file_path(core_file)
    expect(response).to have_http_status(:ok)
  end

  it "renders the profile edit form" do
    get edit_user_path(user)
    expect(response).to have_http_status(:ok)
  end

  it "renders the HTML dashboard" do
    get dashboard_path
    expect(response).to have_http_status(:ok)
  end

  context "when signed out" do
    before { sign_out user }

    it "redirects the new project form to sign in" do
      get new_project_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects the new core file form to sign in" do
      get new_core_file_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
