# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Admin::ProjectMembers", type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:resource) { create(:project_member) }
  let(:index_path) { admin_project_members_path }
  let(:show_path) { admin_project_member_path(resource) }

  before { sign_in admin_user }

  it_behaves_like "an admin controller"

  # Membership acceptance no longer has an admin step — account-level vetting
  # (admin/users review queue) happens before a user can sign in at all, and
  # owner confirmation is the only membership gate.
  describe "owner confirmation of a pending member" do
    let(:owner)           { create(:user) }
    let(:project)         { create(:project, depositor: owner) }
    let!(:pending_member) { create(:project_member, :pending, project: project, user: create(:user)) }

    it "activates on owner confirm with no admin involvement" do
      sign_out admin_user
      sign_in owner
      patch confirm_project_project_member_path(project, pending_member)
      expect(pending_member.reload.status).to eq("active")
    end
  end

  describe "CRUD pages" do
    let(:edit_path) { edit_admin_project_member_path(resource) }
    let(:index_text) { resource.project.title }
    let(:show_text) { resource.user.email }
    let(:param_key) { :project_member }
    let(:valid_update) { { role: "owner" } }
    let(:updated) { -> { resource.reload.role == "owner" } }
    let(:invalid_update) { { role: "bogus" } }

    it_behaves_like "admin CRUD pages"
  end

  it "offers the role as a choice of valid roles" do
    get edit_admin_project_member_path(resource)
    ProjectMember::ROLES.each do |role|
      expect(response.body).to match(/<option[^>]*value="#{role}"/)
    end
  end
end
