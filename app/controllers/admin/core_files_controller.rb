module Admin
  class CoreFilesController < Admin::BaseController
    admin_index search: %i[title description ography_type tei_authors tei_contributors],
                sort: %i[title ography_type is_public created_at],
                filters: {
                  public: ->(core_files) { core_files.where(is_public: true) },
                  private: ->(core_files) { core_files.where(is_public: false) },
                  ography: ->(core_files) { core_files.where.not(ography_type: nil) },
                  processing_failed: ->(core_files) { core_files.processing_failed },
                  processing_pending: ->(core_files) { core_files.processing_pending }
                }

    before_action :set_core_file, only: %i[show edit update destroy retry_processing]

    def index
      @core_files = index_resources(CoreFile.includes(:depositor))
    end

    def show
    end

    def new
      @core_file = CoreFile.new
    end

    def edit
    end

    def create
      @core_file = CoreFile.new(core_file_params)

      if @core_file.save
        redirect_to [ :admin, @core_file ], notice: "Core file was successfully created."
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      if @core_file.update(core_file_params)
        redirect_to [ :admin, @core_file ], notice: "Core file was successfully updated.", status: :see_other
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      if @core_file.destroy
        redirect_to admin_core_files_path, notice: "Core file was successfully destroyed.", status: :see_other
      else
        redirect_to [ :admin, @core_file ], alert: @core_file.errors.full_messages.to_sentence, status: :see_other
      end
    end

    def retry_processing
      if @core_file.retry_processing!
        redirect_to admin_core_file_path(@core_file), notice: "File re-queued for processing."
      else
        redirect_to admin_core_file_path(@core_file), flash: { error: "Cannot retry processing for this file." }
      end
    end

    private

    def set_core_file
      @core_file = CoreFile.find(params.expect(:id))
    end

    def core_file_params
      params.expect(core_file: [ :title, :description, :depositor_id, :ography_type, :is_public, collection_ids: [] ])
    end
  end
end
