module Admin
  class CollectionsController < Admin::BaseController
    admin_index search: %i[title description],
                sort: %i[title is_public created_at],
                filters: {
                  public: ->(collections) { collections.where(is_public: true) },
                  private: ->(collections) { collections.where(is_public: false) }
                }

    before_action :set_collection, only: %i[show edit update destroy]

    def index
      @collections = index_resources(Collection.includes(:project, :depositor))
    end

    def show
    end

    def new
      @collection = Collection.new
    end

    def edit
    end

    def create
      @collection = Collection.new(collection_params)

      if @collection.save
        redirect_to [ :admin, @collection ], notice: "Collection was successfully created."
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      if @collection.update(collection_params)
        redirect_to [ :admin, @collection ], notice: "Collection was successfully updated.", status: :see_other
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      if @collection.destroy
        redirect_to admin_collections_path, notice: "Collection was successfully destroyed.", status: :see_other
      else
        redirect_to [ :admin, @collection ], alert: @collection.errors.full_messages.to_sentence, status: :see_other
      end
    end

    private

    def set_collection
      @collection = Collection.find(params.expect(:id))
    end

    def collection_params
      without_blank_image_file(params.expect(collection: [ :depositor_id, :description, :is_public, :project_id, :title, image_file_attributes: [ :id, :title, :description, :image_url, :file_format, :depositor_id, :_destroy ] ]))
    end
  end
end
