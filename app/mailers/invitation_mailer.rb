# frozen_string_literal: true

class InvitationMailer < ApplicationMailer
  # Notifies admin that a user has requested to join a project and needs vetting.
  def admin_vetting_notification(project_member)
    @member  = project_member
    @project = project_member.project
    @user    = project_member.user

    admin_emails = User.where.not(admin_at: nil).pluck(:email)
    mail(to: admin_emails, subject: "New membership request for \"#{@project.title}\" needs review")
  end

  # Notifies project owner that admin has approved a pending member; owner must confirm.
  def owner_confirmation_request(project_member)
    @member       = project_member
    @project      = project_member.project
    @user         = project_member.user
    @confirm_url  = confirm_project_project_member_url(@project, @member)

    owner_emails = @project.project_members.where(role: "owner", status: :active).joins(:user).pluck("users.email")
    mail(to: owner_emails, subject: "Please confirm #{@user.name}'s membership in \"#{@project.title}\"")
  end
end
