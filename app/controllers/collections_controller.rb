class CollectionsController < ApplicationController
  before_action :authenticate_user!, only: [ :new, :create, :edit, :update, :destroy ]
  before_action :set_collection, only: [ :show, :edit, :update, :destroy ]

  def show
    authorize! :read, @collection
    @core_files = @collection.core_files.accessible_by(current_ability)
  end

  def index
    @collections = Collection.accessible_by(current_ability).includes(:project)
    respond_to do |format|
      format.html
      format.json { render json: @collections }
    end
  end

  def new
    @collection = Collection.new(project_id: params[:project_id])
  end

  def edit
    authorize! :update, @collection
  end

  def create
    @collection = Collection.new(collection_params)
    @collection.depositor = current_user
    authorize! :create, @collection

    if @collection.save
      respond_to do |format|
        format.html { redirect_to collection_path(@collection), notice: "\"#{@collection.title}\" has been created." }
        format.json { render json: @collection, status: :created }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { errors: @collection.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def update
    authorize! :update, @collection
    if @collection.update(collection_params)
      respond_to do |format|
        format.html { redirect_to collection_path(@collection), notice: "\"#{@collection.title}\" has been updated." }
        format.json { render json: @collection, status: :ok }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { errors: @collection.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    authorize! :destroy, @collection
    project = @collection.project
    @collection.destroy
    respond_to do |format|
      format.html { redirect_to project_path(project), notice: "\"#{@collection.title}\" has been deleted." }
      format.json { head :no_content }
    end
  end

  private

  # Projects the current user may create collections in, for the form's
  # project dropdown (owners only — mirrors the :create Collection ability).
  helper_method def ownable_projects
    return Project.all if current_user.admin?

    Project.joins(:project_members)
           .where(project_members: { user_id: current_user.id, role: "owner", status: :active })
  end

  def set_collection
    @collection = Collection.find(params[:id])
  end

  def collection_params
    params.require(:collection).permit(:title, :description, :project_id, :is_public)
  end
end
