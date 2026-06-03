require 'rails_helper'

RSpec.describe "Collections browse page", type: :system do
  let(:user) { create(:user) }
  let!(:project) { create(:project, depositor: user, is_public: true) }
  let!(:public_collection) { create(:collection, title: "Public Collection", depositor: user, project: project, is_public: true) }
  let!(:private_collection) { create(:collection, title: "Private Collection", depositor: user, project: project, is_public: false) }

  context "as a guest" do
    it "renders the page heading" do
      visit collections_path
      expect(page).to have_css("h1", text: "Collections")
    end

    it "lists public collections" do
      visit collections_path
      expect(page).to have_content("Public Collection")
    end

    it "shows the parent project name for each collection" do
      visit collections_path
      expect(page).to have_content("Project: #{project.title}")
    end

    it "does not show private collections" do
      visit collections_path
      expect(page).not_to have_content("Private Collection")
    end
  end

  context "as the collection owner" do
    before { sign_in_as(user) }

    it "shows their own private collection" do
      visit collections_path
      expect(page).to have_content("Private Collection")
    end
  end
end
