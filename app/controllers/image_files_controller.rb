# frozen_string_literal: true

class ImageFilesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_imageable

  def create
    existing = @imageable.image_file
    @image_file = ImageFile.new(image_file_params.merge(imageable: @imageable, depositor: current_user))
    authorize! :create, @image_file

    existing&.destroy

    if @image_file.save
      render json: @image_file, status: :created
    else
      render json: { errors: @image_file.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @image_file = @imageable.image_file
    raise ActiveRecord::RecordNotFound unless @image_file
    authorize! :destroy, @image_file
    @image_file.destroy
    head :no_content
  end

  private

  def set_imageable
    @imageable = if params[:user_id]
      User.find(params[:user_id])
    elsif params[:project_id]
      Project.find(params[:project_id])
    elsif params[:collection_id]
      Collection.find(params[:collection_id])
    elsif params[:core_file_id]
      CoreFile.find(params[:core_file_id])
    end
  end

  def image_file_params
    params.require(:image_file).permit(:title, :alt_text, :image_url, :file)
  end
end
