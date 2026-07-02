module Admin
  class ProjectInvitationsController < Admin::ApplicationController
    # GET /admin/project_invitations
    #
    # Deliberately not a scaffolded Administrate resource: ProjectInvitation#token
    # is a live, unhashed bearer credential, so this view is limited to what an
    # admin needs to audit/revoke a link, same as a project owner already sees.
    def index
      @active_invitations = ProjectInvitation.active.includes(:project, :creator).order(created_at: :desc)
    end

    # PATCH /admin/project_invitations/:id/revoke
    def revoke
      invitation = ProjectInvitation.find(params[:id])
      invitation.update!(revoked_at: Time.current)
      redirect_to admin_project_invitations_path, notice: "Invitation revoked."
    end
  end
end
