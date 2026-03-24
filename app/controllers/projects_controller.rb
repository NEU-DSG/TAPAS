class ProjectsController < ApplicationController
  before_action :authenticate_user!, only: [ :create, :update, :destroy ]
  before_action :set_project, only: [ :update, :destroy ]

  def index
    @projects = if current_user
      member_project_ids = current_user.project_members.pluck(:project_id)
      Project.where(is_public: true).or(Project.where(id: member_project_ids))
    else
      Project.where(is_public: true)
    end
    render json: @projects
  end

  def create
    authorize! :create, Project
    @project = Project.new(project_params)
    @project.depositor = current_user
    if @project.image_file
      @project.image_file.depositor_id = current_user.id
    end

    if @project.save
      render json: @project, status: :created
    else
      render json: { errors: @project.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    authorize! :update, @project

    @project.assign_attributes(project_params)
    if @project.image_file
      @project.image_file.depositor_id = current_user.id
    end

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

  def project_params
    params.require(:project).permit(:title, :description, :institution, :is_public,
      image_file_attributes: [:id, :title, :alt_text, :file, :image_url, :_destroy])
  end
end
