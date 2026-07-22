module Admin
  class UsersController < Admin::ApplicationController
    # GET /admin/users/review_queue
    def review_queue
      @pending_users = User.pending_review.order(created_at: :asc)
      @invitations_by_token = ProjectInvitation
        .where(token: @pending_users.filter_map(&:signup_invitation_token))
        .includes(:project).index_by(&:token)
    end

    # PATCH /admin/users/:id/approve_account
    def approve_account
      user = User.pending_review.find(params[:id])
      user.update!(account_status: :active)
      AccountReviewMailer.account_approved(user).deliver_later
      redirect_to review_queue_admin_users_path, notice: "#{user.name || user.email}'s account is now active and they have been notified."
    end

    # DELETE /admin/users/:id/reject_account
    # Rejection is silent by design — the registrant gets no email.
    def reject_account
      user = User.pending_review.find(params[:id])
      user.destroy!
      redirect_to review_queue_admin_users_path, notice: "#{user.name || user.email}'s registration was rejected and the account removed."
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
