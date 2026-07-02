module Admin
  class ProjectMembersController < Admin::ApplicationController
    # GET /admin/project_members/review_queue
    def review_queue
      @pending_members = ProjectMember.pending.where(needs_admin_vetting: true)
        .includes(:user, :project).order(created_at: :asc)
    end

    # PATCH /admin/project_members/:id/approve
    def approve
      member = ProjectMember.find(params[:id])

      unless member.pending?
        redirect_to admin_project_member_path(member), alert: "Member is not in pending status."
        return
      end

      member.update!(needs_admin_vetting: false)
      InvitationMailer.owner_confirmation_request(member).deliver_later
      redirect_to admin_project_member_path(member), notice: "Member approved; owner notified to confirm."
    end

    # Overwrite any of the RESTful controller actions to implement custom behavior
    # For example, you may want to send an email after a foo is updated.
    #
    # def update
    #   super
    #   send_foo_updated_email(requested_resource)
    # end

    # Override this method to specify custom lookup behavior.
    # This will be used to set the resource for the `show`, `edit`, and `update`
    # actions.
    #
    # def find_resource(param)
    #   Foo.find_by!(slug: param)
    # end

    # The result of this lookup will be available as `requested_resource`

    # Override this if you have certain roles that require a subset
    # this will be used to set the records shown on the `index` action.
    #
    # def scoped_resource
    #   if current_user.super_admin?
    #     resource_class
    #   else
    #     resource_class.with_less_stuff
    #   end
    # end

    # Override `resource_params` if you want to transform the submitted
    # data before it's persisted. For example, the following would turn all
    # empty values into nil values. It uses other APIs such as `resource_class`
    # and `dashboard`:
    #
    # def resource_params
    #   params.require(resource_class.model_name.param_key).
    #     permit(dashboard.permitted_attributes(action_name)).
    #     transform_values { |value| value == "" ? nil : value }
    # end

    # See https://administrate-demo.herokuapp.com/customizing_controller_actions
    # for more information
  end
end
