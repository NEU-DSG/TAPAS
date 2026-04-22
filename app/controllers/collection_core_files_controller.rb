# frozen_string_literal: true

class CollectionCoreFilesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_collection
  before_action :set_collection_core_file, only: [ :destroy ]

  def create
    core_file = CoreFile.find(params[:core_file_id])
    @collection_core_file = CollectionCoreFile.new(collection: @collection, core_file: core_file)
    authorize! :create, @collection_core_file

    if @collection_core_file.save
      render json: @collection_core_file, status: :created
    else
      render json: { errors: @collection_core_file.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    authorize! :destroy, @collection_core_file
    @collection_core_file.destroy
    head :no_content
  end

  private

  def set_collection
    @collection = Collection.find(params[:collection_id])
  end

  def set_collection_core_file
    @collection_core_file = @collection.collection_core_files.find(params[:id])
  end
end
