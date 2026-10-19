module Admin
  class CollectionCoreFilesController < Admin::BaseController
    admin_index sort: %i[id created_at]

    before_action :set_collection_core_file, only: %i[show edit update destroy]

    def index
      @collection_core_files = index_resources(CollectionCoreFile.includes(:collection, :core_file))
    end

    def show
    end

    def new
      @collection_core_file = CollectionCoreFile.new
    end

    def edit
    end

    def create
      @collection_core_file = CollectionCoreFile.new(collection_core_file_params)

      if @collection_core_file.save
        redirect_to [ :admin, @collection_core_file ], notice: "Collection core file was successfully created."
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      if @collection_core_file.update(collection_core_file_params)
        redirect_to [ :admin, @collection_core_file ], notice: "Collection core file was successfully updated.", status: :see_other
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      if @collection_core_file.destroy
        redirect_to admin_collection_core_files_path, notice: "Collection core file was successfully destroyed.", status: :see_other
      else
        redirect_to [ :admin, @collection_core_file ], alert: @collection_core_file.errors.full_messages.to_sentence, status: :see_other
      end
    end

    private

    def set_collection_core_file
      @collection_core_file = CollectionCoreFile.find(params.expect(:id))
    end

    def collection_core_file_params
      params.expect(collection_core_file: [ :collection_id, :core_file_id ])
    end
  end
end
