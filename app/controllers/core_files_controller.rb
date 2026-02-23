class CoreFilesController < ApplicationController
  before_action :authenticate_user!, only: [ :create, :update, :destroy ]
  before_action :set_core_file, only: [ :update, :destroy ]

  def index
    @core_files = CoreFile.all
  end

  def create
    @core_file = CoreFile.new(core_file_params)
    @core_file.depositor = current_user

    if @core_file.save
      render json: @core_file, status: :created
    else
      render json: { errors: @core_file.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @core_file.update(core_file_params)
      render json: @core_file, status: :ok
    else
      render json: { errors: @core_file.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
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
