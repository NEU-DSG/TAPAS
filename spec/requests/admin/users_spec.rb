# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Admin::Users", type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:resource) { create(:user) }
  let(:index_path) { admin_users_path }
  let(:show_path) { admin_user_path(resource) }

  before { sign_in admin_user }

  it_behaves_like "an admin controller"

  describe "GET /admin/users/review_queue" do
    let!(:pending_user) { create(:user, :pending_review) }
    let!(:active_user)  { create(:user) }

    it "returns ok" do
      get review_queue_admin_users_path
      expect(response).to have_http_status(:ok)
    end

    it "shows accounts pending review" do
      get review_queue_admin_users_path
      expect(response.body).to include(pending_user.email)
    end

    it "excludes active accounts" do
      get review_queue_admin_users_path
      expect(response.body).not_to include(active_user.email)
    end

    it "labels direct sign-ups that carried no invitation" do
      get review_queue_admin_users_path
      expect(response.body).to include("Direct sign-up")
    end

    context "when the signup carried a usable invitation token" do
      let(:project)    { create(:project) }
      let(:invitation) { create(:project_invitation, project: project) }
      let!(:pending_user) { create(:user, :pending_review, signup_invitation_token: invitation.token) }

      it "shows the project the user was invited to" do
        get review_queue_admin_users_path
        expect(response.body).to include(project.title)
      end
    end

    context "when not signed in as admin" do
      before { sign_out admin_user; sign_in create(:user) }

      it "redirects away from admin" do
        get review_queue_admin_users_path
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "PATCH /admin/users/:id/approve_account" do
    let!(:pending_user) { create(:user, :pending_review) }

    it "activates the account" do
      patch approve_account_admin_user_path(pending_user)
      expect(pending_user.reload).to be_active
    end

    it "enqueues an approval email to the user" do
      expect {
        patch approve_account_admin_user_path(pending_user)
      }.to have_enqueued_mail(AccountReviewMailer, :account_approved)
    end

    it "redirects back to the queue with a notice" do
      patch approve_account_admin_user_path(pending_user)
      expect(response).to redirect_to(review_queue_admin_users_path)
      expect(flash[:notice]).to be_present
    end

    it "returns not found for an account that is not pending" do
      patch approve_account_admin_user_path(create(:user))
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /admin/users/:id/reject_account" do
    let!(:pending_user) { create(:user, :pending_review) }

    it "deletes the account" do
      expect {
        delete reject_account_admin_user_path(pending_user)
      }.to change(User, :count).by(-1)
      expect(User.exists?(pending_user.id)).to be(false)
    end

    it "sends the registrant nothing — rejection is silent" do
      expect {
        delete reject_account_admin_user_path(pending_user)
      }.not_to have_enqueued_mail
    end

    it "redirects back to the queue with a notice" do
      delete reject_account_admin_user_path(pending_user)
      expect(response).to redirect_to(review_queue_admin_users_path)
      expect(flash[:notice]).to be_present
    end

    it "returns not found for an account that is not pending" do
      delete reject_account_admin_user_path(create(:user))
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /admin/users/bulk_approve_accounts" do
    let!(:pending_users) { create_list(:user, 2, :pending_review) }
    let!(:untouched_user) { create(:user, :pending_review) }

    it "activates every selected account" do
      patch bulk_approve_accounts_admin_users_path, params: { user_ids: pending_users.map(&:id) }
      expect(pending_users.map { |u| u.reload.account_status }).to all(eq("active"))
    end

    it "leaves accounts that were not selected untouched" do
      patch bulk_approve_accounts_admin_users_path, params: { user_ids: pending_users.map(&:id) }
      expect(untouched_user.reload).to be_pending_review
    end

    it "enqueues an approval email for each selected account" do
      expect {
        patch bulk_approve_accounts_admin_users_path, params: { user_ids: pending_users.map(&:id) }
      }.to have_enqueued_mail(AccountReviewMailer, :account_approved).twice
    end

    it "redirects back to the queue with a notice" do
      patch bulk_approve_accounts_admin_users_path, params: { user_ids: pending_users.map(&:id) }
      expect(response).to redirect_to(review_queue_admin_users_path)
      expect(flash[:notice]).to be_present
    end

    it "redirects with an alert when nothing is selected" do
      patch bulk_approve_accounts_admin_users_path, params: { user_ids: [] }
      expect(response).to redirect_to(review_queue_admin_users_path)
      expect(flash[:alert]).to be_present
    end
  end

  describe "DELETE /admin/users/bulk_reject_accounts" do
    let!(:pending_users) { create_list(:user, 2, :pending_review) }
    let!(:untouched_user) { create(:user, :pending_review) }

    it "deletes every selected account" do
      expect {
        delete bulk_reject_accounts_admin_users_path, params: { user_ids: pending_users.map(&:id) }
      }.to change(User, :count).by(-2)
    end

    it "leaves accounts that were not selected untouched" do
      delete bulk_reject_accounts_admin_users_path, params: { user_ids: pending_users.map(&:id) }
      expect(User.exists?(untouched_user.id)).to be(true)
    end

    it "sends the registrants nothing — rejection is silent" do
      expect {
        delete bulk_reject_accounts_admin_users_path, params: { user_ids: pending_users.map(&:id) }
      }.not_to have_enqueued_mail
    end

    it "redirects with an alert when nothing is selected" do
      delete bulk_reject_accounts_admin_users_path, params: { user_ids: [] }
      expect(response).to redirect_to(review_queue_admin_users_path)
      expect(flash[:alert]).to be_present
    end
  end

  describe "GET /admin/users (index)" do
    let!(:alice) { create(:user, name: "Alice Archivist", email: "alice@example.com", institution: "Northeastern") }
    let!(:bob)   { create(:user, name: "Bob Bibliographer", email: "bob@example.com", institution: "Brown") }

    it "lists users" do
      get admin_users_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("alice@example.com", "bob@example.com")
    end

    it "searches name, email and institution" do
      get admin_users_path, params: { search: "northeastern" }
      expect(response.body).to include("alice@example.com")
      expect(response.body).not_to include("bob@example.com")
    end

    it "does not search password hashes" do
      get admin_users_path, params: { search: alice.encrypted_password[0, 12] }
      expect(response.body).not_to include("alice@example.com")
    end

    it "applies the admin: search filter" do
      get admin_users_path, params: { search: "admin:" }
      expect(response.body).to include(admin_user.email)
      expect(response.body).not_to include("alice@example.com")
    end

    it "has no New user button" do
      get admin_users_path
      expect(response.body).not_to include(new_admin_user_path)
    end

    it "shows a button for each search filter, with how to type it" do
      get admin_users_path
      expect(response.body).to include(%(href="#{admin_users_path(search: "admin:")}"))
      expect(response.body).to include(%(href="#{admin_users_path(search: "active:")}"))
      expect(response.body).to include("<code>admin:</code>")
    end

    it "turns a filter button off when that filter is on, keeping other search terms" do
      get admin_users_path, params: { search: "alice admin:" }
      admin_button = Nokogiri::HTML(response.body).at_css("a.filter-btn[title='Remove the admin: filter']")
      expect(admin_button["class"]).to include("active")
      expect(admin_button["href"]).to eq(admin_users_path(search: "alice"))

      active_button = Nokogiri::HTML(response.body).at_css("a.filter-btn[title='Show only matches for active:']")
      expect(active_button["class"]).not_to include("active")
      expect(active_button["href"]).to eq(admin_users_path(search: "alice admin: active:"))
    end

    it "keeps the current sort when a filter button is clicked" do
      get admin_users_path, params: { order: "name", direction: "desc", page: 2 }
      button = Nokogiri::HTML(response.body).at_css("a.filter-btn[title='Show only matches for admin:']")
      expect(button["href"]).to eq(admin_users_path(order: "name", direction: "desc", search: "admin:"))
    end

    it "marks every sortable column with an arrow, solid on the sorted one" do
      get admin_users_path, params: { order: "name", direction: "desc" }
      headers = Nokogiri::HTML(response.body).css("thead a.sort-link")
      expect(headers.size).to eq(6)
      expect(headers.map { |link| link.at_css(".sort-link__arrow").text }).to all(be_in(%w[↕ ▲ ▼]))

      sorted = headers.select { |link| link["class"].include?("sort-link--active") }
      expect(sorted.map { |link| [ link.text.strip, link.at_css(".sort-link__arrow").text ] }).to eq([ [ "Name ▼", "▼" ] ])
      expect(headers.find { |link| link.text.start_with?("Email") }["title"]).to eq("Sort by Email")
    end

    it "sets aria-sort only on the sorted column" do
      get admin_users_path, params: { order: "name", direction: "desc" }
      expect(Nokogiri::HTML(response.body).css("thead th[aria-sort]").map { |th| [ th.text.strip, th["aria-sort"] ] })
        .to eq([ [ "Name ▼", "descending" ] ])
    end

    it "sorts by an allowed column in either direction" do
      get admin_users_path, params: { order: "name", direction: "desc" }
      expect(response.body.index("Bob Bibliographer")).to be < response.body.index("Alice Archivist")

      get admin_users_path, params: { order: "name", direction: "asc" }
      expect(response.body.index("Alice Archivist")).to be < response.body.index("Bob Bibliographer")
    end

    it "ignores sort columns that are not allowed" do
      get admin_users_path, params: { order: "encrypted_password" }
      expect(response).to have_http_status(:ok)
    end

    it "paginates 20 per page" do
      create_list(:user, 20)
      get admin_users_path
      expect(response.body).to include(%(class="pagination"))
      expect(response.body.scan(%(class="action-show")).size).to eq(20)

      get admin_users_path, params: { page: 2 }
      expect(response.body.scan(%(class="action-show")).size).to eq(3)
    end
  end

  describe "GET /admin/users/:id (show)" do
    it "shows sign-in details but not credential fields" do
      resource.update!(last_sign_in_ip: "192.0.2.10")
      get admin_user_path(resource)

      expect(response.body).to include("192.0.2.10")
      expect(response.body).not_to include(resource.encrypted_password)
      expect(response.body).not_to include("Encrypted password")
      expect(response.body).not_to include("Reset password token")
    end
  end

  describe "POST /admin/users (create)" do
    it "re-renders the form with errors when invalid" do
      post admin_users_path, params: { user: { email: "" } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /admin/users/:id (update)" do
    let(:blank_image) { { title: "", description: "", image_url: "", file_format: "", depositor_id: "" } }

    it "updates the user" do
      patch admin_user_path(resource), params: { user: { name: "Renamed" } }
      expect(response).to redirect_to(admin_user_path(resource))
      expect(resource.reload.name).to eq("Renamed")
    end

    it "saves when the image fields are left blank" do
      patch admin_user_path(resource), params: { user: { name: "Renamed", image_file_attributes: blank_image } }
      expect(response).to redirect_to(admin_user_path(resource))
      expect(resource.reload.name).to eq("Renamed")
      expect(resource.image_file).to be_nil
    end

    it "creates an image when the image fields are filled in" do
      image = { title: "Avatar", image_url: "https://example.com/a.png", file_format: "png", depositor_id: resource.id }
      patch admin_user_path(resource), params: { user: { image_file_attributes: image } }
      expect(resource.reload.image_file.title).to eq("Avatar")
    end

    it "re-renders the form with errors when invalid" do
      patch admin_user_path(resource), params: { user: { email: "" } }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "rejects a half-filled image and keeps the user unchanged" do
      patch admin_user_path(resource), params: { user: { name: "Renamed", image_file_attributes: blank_image.merge(title: "Avatar") } }
      expect(response).to have_http_status(:unprocessable_content)
      expect(resource.reload.name).not_to eq("Renamed")
      expect(resource.image_file).to be_nil
    end
  end

  describe "GET /admin/users/:id/edit (image fields)" do
    it "marks the optional image fields as not required" do
      get edit_admin_user_path(resource)
      image_fields = Nokogiri::HTML(response.body).at_css("fieldset.field-unit--nested")
      expect(image_fields.text).to include("Leave every field blank to save without an image.")
      expect(image_fields.css("[required], abbr[title=required]")).to be_empty
    end
  end

  describe "DELETE /admin/users/:id (destroy)" do
    it "deletes the user" do
      delete admin_user_path(resource)
      expect(response).to redirect_to(admin_users_path)
      expect(User.exists?(resource.id)).to be false
    end
  end
end
