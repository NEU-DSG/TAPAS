# frozen_string_literal: true

class InvitationsController < ApplicationController
  before_action :find_invitation

  # GET /invitations/:token
  def show
    store_location_for(:user, request.path) unless user_signed_in?
    # @invitation and @project set by before_action
    # renders invitations/show.html.erb
  end

  # POST /invitations/:token/accept
  def accept
    unless user_signed_in?
      store_location_for(:user, invitation_path(params[:token]))
      redirect_to new_user_session_path, alert: "Please sign in to accept this invitation."
      return
    end

    unless @invitation.usable?
      redirect_to root_path, alert: "This invitation link has expired or been revoked."
      return
    end

    if @project.project_members.exists?(user: current_user)
      redirect_to root_path, notice: "You are already a member of this project."
      return
    end

    # New-to-TAPAS accounts registered via the invite link go through admin vetting
    # before the owner is asked to confirm — established users skip straight to the owner.
    needs_admin_vetting = session.delete(:new_registration).present?
    member = @project.project_members.create!(
      user: current_user, role: "contributor", status: :pending, needs_admin_vetting: needs_admin_vetting
    )

    if needs_admin_vetting
      InvitationMailer.admin_vetting_notification(member).deliver_later
      redirect_to root_path, notice: "Your account and your request to join \"#{@project.title}\" are pending admin review."
    else
      InvitationMailer.owner_confirmation_request(member).deliver_later
      redirect_to root_path, notice: "Your request to join \"#{@project.title}\" is pending owner confirmation."
    end
  rescue ActiveRecord::RecordInvalid => e
    redirect_to invitation_path(params[:token]), alert: e.message
  end

  private

  def find_invitation
    @invitation = ProjectInvitation.find_by(token: params[:token])

    if @invitation.nil?
      redirect_to root_path, alert: "Invitation not found."
    else
      @project = @invitation.project
    end
  end
end
