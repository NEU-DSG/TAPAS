require 'rails_helper'

# Browser check of the homemade admin user pages: list, search, sort, view,
# edit and save, as an admin would use them.
RSpec.describe "Admin users", type: :system do
  let(:admin) { create(:user, :admin, name: "Ada Admin") }
  let!(:user) { create(:user, name: "Grace Reader", email: "grace@example.com", institution: "Northeastern") }

  before do
    sign_in_as(admin)
    visit admin_users_path
  end

  it "lists, searches and sorts users" do
    expect(page).to have_css("tbody tr", text: "grace@example.com")

    fill_in "search", with: "northeastern"
    find_field("search").send_keys(:enter)
    expect(page).to have_css("tbody tr", count: 1)
    expect(page).to have_css("tbody tr", text: "grace@example.com")

    find(".search__clear-link").click
    expect(page).to have_css("thead .sort-link__arrow", text: "↕", count: 6)
    click_link "Sort by Name"
    expect(page).to have_css("th[aria-sort='ascending']", text: "Name ▲")
  end

  it "turns a search filter on and off with its button" do
    expect(page).to have_css("tbody tr", count: 2)

    click_link "Admin", class: "filter-btn"
    expect(page).to have_css("tbody tr", count: 1)
    expect(page).to have_css("tbody tr", text: admin.email)
    expect(find_field("search").value).to eq("admin:")
    expect(page).to have_css("a.filter-btn.active", text: "Admin")

    click_link "Admin", class: "filter-btn"
    expect(page).to have_css("tbody tr", count: 2)
    expect(find_field("search").value).to eq("")
  end

  it "edits and saves a user without an image" do
    click_link "grace@example.com"
    expect(page).to have_css("h1", text: "grace@example.com")

    click_link "Edit grace@example.com"
    fill_in "Name", with: "Grace Renamed"
    click_button "Update User"

    expect(page).to have_text("User was successfully updated.")
    expect(page).to have_text("Grace Renamed")
    expect(user.reload.name).to eq("Grace Renamed")
  end

  it "shows validation errors without leaving the form" do
    click_link "grace@example.com"
    click_link "Edit grace@example.com"
    fill_in "Email", with: ""
    click_button "Update User"

    expect(page).to have_text("can't be blank")
    expect(user.reload.email).to eq("grace@example.com")
  end

  it "deletes a user only after confirmation" do
    within("tbody tr", text: "grace@example.com") do
      dismiss_confirm { click_button "Destroy" }
    end
    expect(User.exists?(user.id)).to be true

    within("tbody tr", text: "grace@example.com") do
      accept_confirm { click_button "Destroy" }
    end
    expect(page).to have_text("User was successfully destroyed.")
    expect(User.exists?(user.id)).to be false
  end
end
