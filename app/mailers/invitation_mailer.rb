# frozen_string_literal: true

class InvitationMailer < ApplicationMailer
  # Asks the project owner to confirm a pending member. Sent on every
  # acceptance — account-level vetting has already happened by this point.
  def owner_confirmation_request(project_member)
    @member       = project_member
    @project      = project_member.project
    @user         = project_member.user
    @confirm_url  = confirm_landing_project_project_member_url(@project, @member)

    owner_emails = @project.project_members.where(role: "owner", status: :active).joins(:user).pluck("users.email")
    mail(to: owner_emails, subject: "Please confirm #{@user.name || @user.email}'s membership in \"#{@project.title}\"")
  end
end
