module Admin
  class ProjectMembersController < Admin::BaseController
    admin_index search: %i[role],
                sort: %i[id is_project_depositor role]

    before_action :set_project_member, only: %i[show edit update destroy]

    def index
      @project_members = index_resources(ProjectMember.includes(:project))
    end

    def show
    end

    def new
      @project_member = ProjectMember.new
    end

    def edit
    end

    def create
      @project_member = ProjectMember.new(project_member_params)

      if @project_member.save
        redirect_to [ :admin, @project_member ], notice: "Project member was successfully created."
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      if @project_member.update(project_member_params)
        redirect_to [ :admin, @project_member ], notice: "Project member was successfully updated.", status: :see_other
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      if @project_member.destroy
        redirect_to admin_project_members_path, notice: "Project member was successfully destroyed.", status: :see_other
      else
        redirect_to [ :admin, @project_member ], alert: @project_member.errors.full_messages.to_sentence, status: :see_other
      end
    end

    private

    def set_project_member
      @project_member = ProjectMember.find(params.expect(:id))
    end

    def project_member_params
      params.expect(project_member: [ :is_project_depositor, :project_id, :role, :user_id ])
    end
  end
end
