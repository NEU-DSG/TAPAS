# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Admin::ProjectMembers", type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:resource) { create(:project_member) }
  let(:index_path) { admin_project_members_path }
  let(:show_path) { admin_project_member_path(resource) }

  before { sign_in admin_user }

  it_behaves_like "an admin controller"

  describe "PATCH /admin/project_members/:id/approve" do
    let(:project) { create(:project) }
    let(:member_user) { create(:user) }
    let!(:pending_member) { create(:project_member, :pending, project: project, user: member_user) }

    it "leaves the member in pending status" do
      patch approve_admin_project_member_path(pending_member)
      expect(pending_member.reload.status).to eq("pending")
    end

    it "enqueues an owner confirmation request email" do
      expect {
        patch approve_admin_project_member_path(pending_member)
      }.to have_enqueued_mail(InvitationMailer, :owner_confirmation_request)
    end

    it "redirects to the member show page with a notice" do
      patch approve_admin_project_member_path(pending_member)
      expect(response).to redirect_to(admin_project_member_path(pending_member))
      expect(flash[:notice]).to be_present
    end

    context "when the member needed admin vetting" do
      let!(:pending_member) { create(:project_member, :needs_admin_vetting, project: project, user: member_user) }

      it "clears the needs_admin_vetting flag" do
        patch approve_admin_project_member_path(pending_member)
        expect(pending_member.reload.needs_admin_vetting).to eq(false)
      end
    end

    context "when the member is not pending" do
      let!(:active_member) { create(:project_member, project: project, user: create(:user)) }

      it "redirects with an alert and does not change status" do
        patch approve_admin_project_member_path(active_member)
        expect(response).to redirect_to(admin_project_member_path(active_member))
        expect(flash[:alert]).to be_present
      end
    end

    context "when not signed in as admin" do
      before { sign_out admin_user; sign_in create(:user) }

      it "redirects away from admin" do
        patch approve_admin_project_member_path(pending_member)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET /admin/project_members/review_queue" do
    let(:project) { create(:project) }
    let!(:needs_vetting_member) { create(:project_member, :needs_admin_vetting, project: project, user: create(:user)) }
    let!(:plain_pending_member) { create(:project_member, :pending, project: project, user: create(:user)) }
    let!(:active_member)        { create(:project_member, project: project, user: create(:user)) }

    it "returns ok" do
      get review_queue_admin_project_members_path
      expect(response).to have_http_status(:ok)
    end

    it "shows members needing admin vetting" do
      get review_queue_admin_project_members_path
      expect(response.body).to include(needs_vetting_member.user.email)
    end

    it "excludes pending members that don't need vetting" do
      get review_queue_admin_project_members_path
      expect(response.body).not_to include(plain_pending_member.user.email)
    end

    it "excludes active members" do
      get review_queue_admin_project_members_path
      expect(response.body).not_to include(active_member.user.email)
    end

    context "when not signed in as admin" do
      before { sign_out admin_user; sign_in create(:user) }

      it "redirects away from admin" do
        get review_queue_admin_project_members_path
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "full approval workflow: admin approve → owner confirm" do
    let(:owner)          { create(:user) }
    let(:project)        { create(:project, depositor: owner) }
    let(:invitee)        { create(:user) }
    let!(:pending_member) { create(:project_member, :pending, project: project, user: invitee) }

    it "leaves the member pending after admin approves, then activates on owner confirm" do
      patch approve_admin_project_member_path(pending_member)
      expect(pending_member.reload.status).to eq("pending")

      sign_out admin_user
      sign_in owner
      patch confirm_project_project_member_path(project, pending_member)
      expect(pending_member.reload.status).to eq("active")
    end
  end
end
