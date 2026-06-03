require 'rails_helper'

RSpec.describe "Projects browse page", type: :system do
  let(:user) { create(:user) }
  let!(:public_project) { create(:project, title: "Public Project", depositor: user, is_public: true) }
  let!(:private_project) { create(:project, title: "Private Project", depositor: user, is_public: false) }

  context "as a guest" do
    it "renders the page heading" do
      visit projects_path
      expect(page).to have_css("h1", text: "Projects")
    end

    it "lists public projects" do
      visit projects_path
      expect(page).to have_content("Public Project")
    end

    it "does not show private projects" do
      visit projects_path
      expect(page).not_to have_content("Private Project")
    end
  end

  context "as the project owner" do
    before { sign_in_as(user) }

    it "shows their own private project" do
      visit projects_path
      expect(page).to have_content("Private Project")
    end

    it "shows public projects from other users" do
      other_user = create(:user)
      create(:project, title: "Other Public Project", depositor: other_user, is_public: true)

      visit projects_path
      expect(page).to have_content("Other Public Project")
    end
  end
end
