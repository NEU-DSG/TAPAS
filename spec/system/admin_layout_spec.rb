require 'rails_helper'

# Admin pages used to load only Administrate's own JavaScript bundle, so the
# app's Stimulus controllers never ran there. These specs check in a real
# browser that admin pages now load the app's importmap like public pages do.
RSpec.describe "Admin layout", type: :system do
  let(:admin) { create(:user, :admin) }

  context "as an admin" do
    before { sign_in_as(admin) }

    it "loads the app's importmap and starts Stimulus" do
      visit admin_projects_path

      expect(page).to have_css("script[type='importmap']", visible: :all)
      expect(page.evaluate_script("typeof window.Stimulus")).to eq("object")
    end

    it "no longer loads Administrate's JavaScript bundle" do
      visit admin_projects_path

      expect(page).to have_no_css("script[src*='administrate']", visible: :all)
    end

    it "loads without JavaScript errors" do
      # The browser log outlives each example; drain it so an earlier example's
      # expected 422 (a failed form save) isn't counted against this page.
      page.driver.browser.logs.get(:browser)
      visit admin_projects_path

      errors = page.driver.browser.logs.get(:browser).select { |entry| entry.level == "SEVERE" }
      expect(errors.map(&:message)).to be_empty
    end

    context "with a confirmation prompt" do
      let!(:invitation) { create(:project_invitation) }

      before { visit admin_project_invitations_path }

      it "acts only after the admin confirms" do
        accept_confirm("Revoke this invitation link?") { click_button "Revoke" }

        expect(page).to have_text("Invitation revoked.")
        expect(invitation.reload.revoked_at).to be_present
      end

      it "does nothing when the admin cancels" do
        dismiss_confirm("Revoke this invitation link?") { click_button "Revoke" }

        expect(page).to have_no_text("Invitation revoked.")
        expect(invitation.reload.revoked_at).to be_nil
      end
    end
  end

  it "sends a non-admin back to the home page with an error" do
    sign_in_as(create(:user))
    visit admin_projects_path

    expect(page).to have_current_path(root_path)
    expect(page).to have_text("Access denied.")
  end
end
