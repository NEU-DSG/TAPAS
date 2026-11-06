module Admin
  class ProjectsController < Admin::BaseController
    admin_index search: %i[title description institution],
                sort: %i[title institution is_public created_at],
                filters: {
                  public: ->(projects) { projects.where(is_public: true) },
                  private: ->(projects) { projects.where(is_public: false) },
                  recent: ->(projects) { projects.where("created_at > ?", 30.days.ago) }
                }

    before_action :set_project, only: %i[show edit update destroy]

    def index
      @projects = index_resources(filter_by_visibility(Project.includes(:depositor)))
    end

    def show
    end

    def new
      @project = Project.new
    end

    def edit
    end

    def create
      @project = Project.new(project_params)

      if @project.save
        redirect_to [ :admin, @project ], notice: "Project was successfully created."
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      if @project.update(project_params)
        redirect_to [ :admin, @project ], notice: "Project was successfully updated.", status: :see_other
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      if @project.destroy
        redirect_to admin_projects_path, notice: "Project was successfully destroyed.", status: :see_other
      else
        redirect_to [ :admin, @project ], alert: @project.errors.full_messages.to_sentence, status: :see_other
      end
    end

    private

    def set_project
      @project = Project.find(params.expect(:id))
    end

    def project_params
      without_blank_image_file(params.expect(project: [
        :depositor_id, :description, :institution, :is_public, :title,
        image_file_attributes: [ :id, :title, :description, :image_url, :file_format, :depositor_id, :_destroy ]
      ]))
    end

    # The Public/Private buttons remember their choice in the session until
    # "All Projects" clears it.
    def filter_by_visibility(projects)
      session[:project_visibility] = params[:visibility] if params[:visibility].present?
      session[:project_visibility] = nil if params[:clear_filters]

      case session[:project_visibility]
      when "public" then projects.where(is_public: true)
      when "private" then projects.where(is_public: false)
      else projects
      end
    end
  end
end
