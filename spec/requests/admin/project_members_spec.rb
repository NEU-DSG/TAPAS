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

    it "activates the member" do
      patch approve_admin_project_member_path(pending_member)
      expect(pending_member.reload.status).to eq("active")
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
end
