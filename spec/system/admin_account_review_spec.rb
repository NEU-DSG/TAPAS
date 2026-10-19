require 'rails_helper'

# Request specs hit the bulk endpoints directly, so they can't see whether the
# bulk_select Stimulus controller actually rewrites the form's action and
# _method in a browser. These specs drive the real page to cover that.
RSpec.describe "Admin account review queue", type: :system do
  let(:admin) { create(:user, :admin) }
  let!(:first_pending) { create(:user, :pending_review, name: "First Pending") }
  let!(:second_pending) { create(:user, :pending_review, name: "Second Pending") }
  let!(:third_pending) { create(:user, :pending_review, name: "Third Pending") }

  before do
    sign_in_as(admin)
    visit review_queue_admin_users_path
  end

  def row_checkbox(user)
    find("#user_ids_#{user.id}")
  end

  it "selects and clears every row with the select-all checkbox" do
    check "select_all"
    expect(all("input[name='user_ids[]']")).to all(be_checked)

    uncheck "select_all"
    expect(all("input[name='user_ids[]']")).to all(satisfy { |box| !box.checked? })
  end

  it "approves only the selected accounts" do
    row_checkbox(first_pending).check
    row_checkbox(second_pending).check

    accept_confirm { click_button "Approve Selected" }

    expect(page).to have_current_path(review_queue_admin_users_path)
    expect(page).not_to have_content("First Pending")
    expect(first_pending.reload).to be_active
    expect(second_pending.reload).to be_active
    expect(third_pending.reload).to be_pending_review
  end

  it "rejects only the selected accounts" do
    row_checkbox(first_pending).check

    accept_confirm { click_button "Reject Selected" }

    expect(page).to have_current_path(review_queue_admin_users_path)
    expect(page).not_to have_content("First Pending")
    expect(User.exists?(first_pending.id)).to be false
    expect(second_pending.reload).to be_pending_review
  end

  it "alerts and changes nothing when no accounts are selected" do
    accept_alert("No accounts were selected.") { click_button "Approve Selected" }

    expect(page).to have_current_path(review_queue_admin_users_path)
    expect([ first_pending, second_pending, third_pending ].map { |u| u.reload.account_status })
      .to all(eq("pending_review"))
  end

  it "does nothing when the admin cancels the confirmation" do
    row_checkbox(first_pending).check

    dismiss_confirm { click_button "Approve Selected" }

    expect(first_pending.reload).to be_pending_review
  end

  it "approves a single account from its own row" do
    within("tr", text: "Second Pending") do
      accept_confirm { click_button "Approve" }
    end

    # The flash names the user, so check the table rather than the whole page.
    expect(page).to have_text("Second Pending's account is now active")
    expect(page).to have_no_css("tbody tr", text: "Second Pending")
    expect(second_pending.reload).to be_active
    expect(first_pending.reload).to be_pending_review
    expect(third_pending.reload).to be_pending_review
  end

  # Regression: the per-row forms used to be nested inside the bulk form, so
  # the browser folded the first row's Approve button into the bulk form and
  # it approved whichever rows were checked instead of its own.
  it "approves only the first row's account even when other rows are checked" do
    row_checkbox(third_pending).check

    within("tr", text: "First Pending") do
      accept_confirm { click_button "Approve" }
    end

    expect(page).to have_text("First Pending's account is now active")
    expect(first_pending.reload).to be_active
    expect(third_pending.reload).to be_pending_review
  end

  it "rejects a single account from its own row" do
    within("tr", text: "Second Pending") do
      accept_confirm { click_button "Reject" }
    end

    expect(page).to have_text("Second Pending's registration was rejected")
    expect(page).to have_no_css("tbody tr", text: "Second Pending")
    expect(User.exists?(second_pending.id)).to be false
    expect(first_pending.reload).to be_pending_review
  end
end
