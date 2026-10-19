module Admin
  class ImageFilesController < Admin::BaseController
    admin_index search: %i[title description image_url file_format],
                sort: %i[title image_url file_format created_at]

    before_action :set_image_file, only: %i[show edit update destroy]

    def index
      @image_files = index_resources(ImageFile.includes(:imageable))
    end

    def show
    end

    def new
      @image_file = ImageFile.new
    end

    def edit
    end

    def create
      @image_file = ImageFile.new(image_file_params)

      if @image_file.save
        redirect_to [ :admin, @image_file ], notice: "Image file was successfully created."
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      if @image_file.update(image_file_params)
        redirect_to [ :admin, @image_file ], notice: "Image file was successfully updated.", status: :see_other
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      if @image_file.destroy
        redirect_to admin_image_files_path, notice: "Image file was successfully destroyed.", status: :see_other
      else
        redirect_to [ :admin, @image_file ], alert: @image_file.errors.full_messages.to_sentence, status: :see_other
      end
    end

    private

    def set_image_file
      @image_file = ImageFile.find(params.expect(:id))
    end

    def image_file_params
      params.expect(image_file: [ :title, :description, :image_url, :file_format, :depositor_id ])
    end
  end
end
