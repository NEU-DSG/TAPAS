# frozen_string_literal: true

class ProjectMembersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project
  before_action :set_member, only: [ :update, :destroy ]

  # POST /projects/:project_id/project_members
  def create
    authorize! :manage_members, @project
    @member = @project.project_members.build
    @member.user = User.find(params.dig(:project_member, :user_id))
    @member.role = params.dig(:project_member, :role)

    if @member.save
      render json: @member, status: :created
    else
      render json: { errors: @member.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /projects/:project_id/project_members/:id
  def update
    authorize! :manage_members, @project

    @member.role = params.dig(:project_member, :role) if params.dig(:project_member, :role).present?

    if @member.save
      render json: @member, status: :ok
    else
      render json: { errors: @member.errors.full_messages }, status: :unprocessable_entity
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
end
