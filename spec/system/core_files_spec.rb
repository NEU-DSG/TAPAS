require 'rails_helper'

RSpec.describe "Core files browse page", type: :system do
  let(:user) { create(:user) }
  let(:project) { create(:project, depositor: user, is_public: true) }
  let(:collection) { create(:collection, depositor: user, project: project, is_public: true) }
  let!(:public_file) do
    CoreFile.create!(
      title: "Public File",
      depositor: user,
      collections: [ collection ],
      is_public: true
    )
  end
  let!(:private_file) do
    CoreFile.create!(
      title: "Private File",
      depositor: user,
      collections: [ collection ],
      is_public: false
    )
  end

  context "as a guest" do
    it "renders the page heading" do
      visit core_files_path
      expect(page).to have_css("h1", text: "Files")
    end

    it "lists public files" do
      visit core_files_path
      expect(page).to have_content("Public File")
    end

    it "does not show private files" do
      visit core_files_path
      expect(page).not_to have_content("Private File")
    end

    it "shows processing status" do
      visit core_files_path
      expect(page).to have_content("Status:")
    end
  end

  context "as the file owner" do
    before { sign_in_as(user) }

    it "shows their own private file" do
      visit core_files_path
      expect(page).to have_content("Private File")
    end
  end
end
