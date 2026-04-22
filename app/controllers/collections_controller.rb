class CollectionsController < ApplicationController
  before_action :authenticate_user!, only: [ :create, :update, :destroy ]
  before_action :set_collection, only: [ :update, :destroy ]

  def index
    collections = if current_user
      member_project_ids = current_user.project_members.pluck(:project_id)
      Collection.where(is_public: true).or(Collection.where(project_id: member_project_ids))
    else
      Collection.where(is_public: true)
    end
    render json: collections
  end

  def create
    @collection = Collection.new(collection_params)
    @collection.depositor = current_user
    authorize! :create, @collection

    if @collection.save
      render json: @collection, status: :created
    else
      render json: { errors: @collection.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    authorize! :update, @collection
    if @collection.update(collection_params)
      render json: @collection, status: :ok
    else
      render json: { errors: @collection.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    authorize! :destroy, @collection
    @collection.destroy
    head :no_content
  end

  private

  def set_collection
    @collection = Collection.find(params[:id])
  end

  def collection_params
    params.require(:collection).permit(:title, :description, :project_id, :is_public)
  end
end
