class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    owned_projects = Project.joins(:project_members)
                            .where(project_members: { user: current_user, role: "owner" })
    contributed_projects = Project.joins(:project_members)
                                  .where(project_members: { user: current_user, role: "contributor" })

    render json: {
      owned_projects: owned_projects,
      contributed_projects: contributed_projects,
      collections: Collection.accessible_by(current_ability),
      core_files: CoreFile.where(depositor: current_user)
    }
  end
end
