class CoreFilesController < ApplicationController
  before_action :authenticate_user!, only: [ :create, :update, :destroy ]
  before_action :set_core_file, only: [ :update, :destroy ]

  def index
    @core_files = if current_user
      member_project_ids = current_user.project_members.pluck(:project_id)
      member_core_file_ids = CoreFile.joins(:collections)
        .where(collections: { project_id: member_project_ids }).select(:id)
      CoreFile.where(is_public: true).or(CoreFile.where(id: member_core_file_ids))
    else
      CoreFile.where(is_public: true)
    end
  end

  def create
    authorize! :create, CoreFile
    @core_file = CoreFile.new(core_file_params)
    @core_file.depositor = current_user

    if @core_file.save
      render json: @core_file, status: :created
    else
      render json: { errors: @core_file.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    authorize! :update, @core_file
    if @core_file.update(core_file_params)
      render json: @core_file, status: :ok
    else
      render json: { errors: @core_file.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    authorize! :destroy, @core_file
    @core_file.destroy
    head :no_content
  end

  private

  def set_core_file
    @core_file = CoreFile.find(params[:id])
  end

  def core_file_params
    params.require(:core_file).permit(:title, :description, :is_public, :ography_type, :tei_file, collection_ids: [])
  end
end
