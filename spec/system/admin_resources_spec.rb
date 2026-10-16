require 'rails_helper'

# Browser smoke test for each homemade admin resource page: open the list,
# open a record, edit it and save, the way an admin would.
RSpec.describe "Admin resource pages", type: :system do
  let(:admin) { create(:user, :admin) }
  let(:owner) { create(:user, email: "owner@example.com") }
  let(:project) { create(:project, title: "Letters Project", depositor: owner) }
  let(:collection) { create(:collection, title: "Letters Collection", project: project, depositor: owner) }
  let(:core_file) { create(:core_file, title: "Letter One", depositor: owner, collections: [ collection ]) }

  before { sign_in_as(admin) }

  def edit_and_save(index_path:, link_text:, field:, value:)
    visit index_path
    click_link link_text
    click_link "Edit #{link_text}"
    fill_in field, with: value
    click_button(class: nil, type: "submit")
    expect(page).to have_text("was successfully updated.")
    expect(page).to have_text(value)
  end

  it "edits a project" do
    project
    edit_and_save(index_path: admin_projects_path, link_text: "Letters Project", field: "project[title]", value: "Renamed Project")
  end

  it "edits a collection" do
    collection
    edit_and_save(index_path: admin_collections_path, link_text: "Letters Collection", field: "collection[title]", value: "Renamed Collection")
  end

  it "edits a core file and moves it to another collection" do
    core_file
    second = create(:collection, title: "Second Collection", project: project, depositor: owner)

    visit admin_core_files_path
    click_link "Letter One"
    click_link "Edit Letter One"
    unselect "Letters Collection", from: "Collections"
    select "Second Collection", from: "Collections"
    click_button "Update Core file"

    expect(page).to have_text("Core file was successfully updated.")
    expect(core_file.reload.collections).to eq([ second ])
  end

  it "edits an image file" do
    image = create(:image_file, title: "Cover Image")
    edit_and_save(index_path: admin_image_files_path, link_text: "Cover Image", field: "Title", value: "Renamed Image")
    expect(image.reload.title).to eq("Renamed Image")
  end

  it "edits a view package" do
    package = create(:view_package, description: "Reader view")
    visit admin_view_packages_path
    click_link package.id.to_s
    click_link "Edit View package ##{package.id}"
    fill_in "Human name", with: "Renamed Package"
    click_button "Update View package"

    expect(page).to have_text("View package was successfully updated.")
    expect(package.reload.human_name).to eq("Renamed Package")
  end

  it "changes a project member's role" do
    member = project.project_members.first
    visit admin_project_member_path(member)
    click_link "Edit Project member ##{member.id}"
    select "contributor", from: "Role"
    click_button "Update Project member"

    expect(page).to have_text("Project member was successfully updated.")
    expect(member.reload.role).to eq("contributor")
  end

  it "moves a file's collection link to another collection" do
    link = core_file.collection_core_files.first
    create(:collection, title: "Second Collection", project: project, depositor: owner)
    visit admin_collection_core_file_path(link)
    click_link "Edit Collection core file ##{link.id}"
    select "Second Collection", from: "Collection"
    click_button "Update Collection core file"

    expect(page).to have_text("Collection core file was successfully updated.")
    expect(link.reload.collection.title).to eq("Second Collection")
  end

  it "filters projects by visibility" do
    project
    create(:project, title: "Hidden Project", is_public: false)
    visit admin_projects_path
    click_link "Private"

    expect(page).to have_css("tbody tr", text: "Hidden Project")
    expect(page).to have_no_css("tbody tr", text: "Letters Project")
  end
end
