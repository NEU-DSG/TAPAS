module Admin
  class ViewPackagesController < Admin::BaseController
    admin_index search: %i[css_files description dir_name file_type git_branch human_name js_files machine_name parameters run_process],
                sort: %i[id css_files description dir_name]

    before_action :set_view_package, only: %i[show edit update destroy]

    def index
      @view_packages = index_resources(ViewPackage.all)
    end

    def show
    end

    def new
      @view_package = ViewPackage.new
    end

    def edit
    end

    def create
      @view_package = ViewPackage.new(view_package_params)

      if @view_package.save
        redirect_to [ :admin, @view_package ], notice: "View package was successfully created."
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      if @view_package.update(view_package_params)
        redirect_to [ :admin, @view_package ], notice: "View package was successfully updated.", status: :see_other
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      if @view_package.destroy
        redirect_to admin_view_packages_path, notice: "View package was successfully destroyed.", status: :see_other
      else
        redirect_to [ :admin, @view_package ], alert: @view_package.errors.full_messages.to_sentence, status: :see_other
      end
    end

    private

    def set_view_package
      @view_package = ViewPackage.find(params.expect(:id))
    end

    def view_package_params
      params.expect(view_package: [ :css_files, :description, :dir_name, :file_type, :git_branch, :git_timestamp, :human_name, :js_files, :machine_name, :parameters, :run_process ])
    end
  end
end
