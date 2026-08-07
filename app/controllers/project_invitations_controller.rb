# frozen_string_literal: true

class ProjectInvitationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project
  before_action :set_invitation, only: [ :destroy ]

  # POST /projects/:project_id/project_invitations
  def create
    authorize! :manage_members, @project
    @invitation = @project.project_invitations.build(creator: current_user)

    respond_to do |format|
      if @invitation.save
        format.json { render json: { token: @invitation.token, url: invitation_url(@invitation.token), expires_at: @invitation.expires_at }, status: :created }
        format.html { redirect_to project_path(@project), notice: "Invitation link generated." }
      else
        format.json { render json: { errors: @invitation.errors.full_messages }, status: :unprocessable_entity }
        format.html { redirect_to project_path(@project), alert: @invitation.errors.full_messages.to_sentence }
      end
    end
  end

  # DELETE /projects/:project_id/project_invitations/:id
  def destroy
    authorize! :manage_members, @project
    @invitation.update!(revoked_at: Time.current)
    respond_to do |format|
      format.json { head :no_content }
      format.html { redirect_to project_path(@project), notice: "Invitation revoked." }
    end
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_invitation
    @invitation = @project.project_invitations.find(params[:id])
  end
end
