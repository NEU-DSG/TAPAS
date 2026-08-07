class CoreFilesController < ApplicationController
  before_action :authenticate_user!, only: [ :new, :create, :edit, :update, :destroy ]
  before_action :set_core_file, only: [ :show, :edit, :update, :destroy ]

  def show
    authorize! :read, @core_file
    @collections = @core_file.collections.accessible_by(current_ability)
  end

  def index
    @core_files = CoreFile.accessible_by(current_ability)
    respond_to do |format|
      format.html
      format.json { render json: @core_files }
    end
  end

  def new
    authorize! :create, CoreFile
    @core_file = CoreFile.new(collection_ids: [ params[:collection_id] ].compact)
  end

  def edit
    authorize! :update, @core_file
  end

  def create
    authorize! :create, CoreFile
    @core_file = CoreFile.new(core_file_params)
    @core_file.depositor = current_user

    if @core_file.save
      respond_to do |format|
        format.html { redirect_to core_file_path(@core_file), notice: "\"#{@core_file.title}\" has been created." }
        format.json { render json: @core_file, status: :created }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { errors: @core_file.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def update
    authorize! :update, @core_file
    if @core_file.update(core_file_params)
      respond_to do |format|
        format.html { redirect_to core_file_path(@core_file), notice: "\"#{@core_file.title}\" has been updated." }
        format.json { render json: @core_file, status: :ok }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { errors: @core_file.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    authorize! :destroy, @core_file
    collection = @core_file.collections.first
    @core_file.destroy
    respond_to do |format|
      format.html { redirect_to collection ? collection_path(collection) : core_files_path, notice: "\"#{@core_file.title}\" has been deleted." }
      format.json { head :no_content }
    end
  end

  private

  # Collections the current user may deposit files into, for the form's
  # checkboxes (active members of the collection's project).
  helper_method def depositable_collections
    return Collection.all if current_user.admin?

    Collection.where(
      project_id: ProjectMember.where(user: current_user, status: :active).select(:project_id)
    )
  end

  def set_core_file
    @core_file = CoreFile.find(params[:id])
  end

  def core_file_params
    params.require(:core_file).permit(:title, :description, :is_public, :ography_type, :tei_file, collection_ids: [])
  end
end
