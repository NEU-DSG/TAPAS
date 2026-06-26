class ProjectsController < ApplicationController
  before_action :authenticate_user!, only: [ :create, :update, :destroy ]
  before_action :set_project, only: [ :show, :update, :destroy ]

  def show
    authorize! :read, @project
    @active_invitations = @project.project_invitations.active.includes(:creator)
    @pending_members = @project.project_members.pending.includes(:user)
  end

  def index
    @projects = Project.accessible_by(current_ability)
    respond_to do |format|
      format.html
      format.json { render json: @projects }
    end
  end

  def create
    authorize! :create, Project
    @project = Project.new(project_params)
    @project.depositor = current_user
    assign_image_depositor(@project)

    if @project.save
      render json: @project, status: :created
    else
      render json: { errors: @project.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    authorize! :update, @project
    @project.assign_attributes(project_params)
    assign_image_depositor(@project)

    if @project.save
      render json: @project, status: :ok
    else
      render json: { errors: @project.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    authorize! :destroy, @project
    @project.destroy
    head :no_content
  end

  private

  def set_project
    @project = Project.find(params[:id])
  end

  def assign_image_depositor(project)
    project.image_file.depositor_id = current_user.id if project.image_file
  end

  def project_params
    params.require(:project).permit(:title, :description, :institution, :is_public, :website,
      image_file_attributes: [ :id, :title, :alt_text, :file, :image_url, :_destroy ])
  end
end
