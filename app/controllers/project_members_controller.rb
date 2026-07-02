# frozen_string_literal: true

class ProjectMembersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project
  before_action :set_member, only: [ :update, :destroy, :confirm ]

  # POST /projects/:project_id/project_members
  def create
    authorize! :manage_members, @project
    @member = @project.project_members.build
    @member.user = User.find(member_params[:user_id])
    @member.role = member_params[:role]

    if @member.save
      render json: @member, status: :created
    else
      render json: { errors: @member.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /projects/:project_id/project_members/:id
  def update
    authorize! :manage_members, @project

    @member.role = member_params[:role] if params[:project_member].present? && member_params[:role].present?

    if @member.save
      render json: @member, status: :ok
    else
      render json: { errors: @member.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /projects/:project_id/project_members/:id/confirm
  def confirm
    authorize! :manage_members, @project

    unless @member.pending?
      respond_to do |format|
        format.json { render json: { errors: [ "Member is not in pending status" ] }, status: :unprocessable_entity }
        format.html { redirect_to project_path(@project), alert: "Member is not in pending status." }
      end
      return
    end

    if @member.update(status: :active)
      respond_to do |format|
        format.json { render json: @member, status: :ok }
        format.html { redirect_to project_path(@project), notice: "#{@member.user.name || @member.user.email} confirmed as a project member." }
      end
    else
      respond_to do |format|
        format.json { render json: { errors: @member.errors.full_messages }, status: :unprocessable_entity }
        format.html { redirect_to project_path(@project), alert: @member.errors.full_messages.to_sentence }
      end
    end
  end

  # DELETE /projects/:project_id/project_members/:id
  def destroy
    authorize! :manage_members, @project

    if last_owner?
      render json: { errors: [ "Cannot remove the last owner of a project" ] }, status: :unprocessable_entity
      return
    end

    @member.destroy
    head :no_content
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_member
    @member = @project.project_members.find(params[:id])
  end

  def last_owner?
    @member.role == "owner" &&
      @project.project_members.where(role: "owner").count == 1
  end

  def member_params
    params.require(:project_member).permit(:user_id, :role)
  end
end
