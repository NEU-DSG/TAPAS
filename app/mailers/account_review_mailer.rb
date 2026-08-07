# frozen_string_literal: true

class AccountReviewMailer < ApplicationMailer
  # Tells admins a new account is waiting in the review queue.
  def new_registration(user)
    @user = user

    admin_emails = User.where.not(admin_at: nil).pluck(:email)
    mail(to: admin_emails, subject: "New TAPAS account for #{@user.name || @user.email} needs review")
  end

  # Tells the registrant their account was approved. When the signup came from
  # an invitation link that is still usable, the email includes it so they can
  # pick up where they left off. Rejection sends nothing — silent by design.
  def account_approved(user)
    @user = user
    @invitation = ProjectInvitation.find_by(token: user.signup_invitation_token) if user.signup_invitation_token.present?
    @invitation = nil unless @invitation&.usable?

    mail(to: @user.email, subject: "Your TAPAS account has been approved")
  end
end
