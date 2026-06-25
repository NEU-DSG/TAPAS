# frozen_string_literal: true

class ProjectInvitationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project
  before_action :set_invitation, only: [ :destroy ]

  # POST /projects/:project_id/project_invitations
  def create
    authorize! :manage_members, @project
    @invitation = @project.project_invitations.build(creator: current_user)

    if @invitation.save
      render json: { token: @invitation.token, url: invitation_url(@invitation.token), expires_at: @invitation.expires_at }, status: :created
    else
      render json: { errors: @invitation.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /projects/:project_id/project_invitations/:id
  def destroy
    authorize! :manage_members, @project
    @invitation.update!(revoked_at: Time.current)
    head :no_content
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_invitation
    @invitation = @project.project_invitations.find(params[:id])
  end
end
