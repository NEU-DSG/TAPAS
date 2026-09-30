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
      approve!(user)
      redirect_to review_queue_admin_users_path, notice: "#{display_name(user)}'s account is now active and they have been notified."
    end

    # DELETE /admin/users/:id/reject_account
    # Rejection is silent by design — the registrant gets no email.
    def reject_account
      user = User.pending_review.find(params[:id])
      reject!(user)
      redirect_to review_queue_admin_users_path, notice: "#{display_name(user)}'s registration was rejected and the account removed."
    end

    # PATCH /admin/users/bulk_approve_accounts
    def bulk_approve_accounts
      users = pending_selection
      return redirect_with_no_selection if users.empty?

      users.each { |user| approve!(user) }
      redirect_to review_queue_admin_users_path, notice: "#{users.size} account(s) are now active and their owners have been notified."
    end

    # DELETE /admin/users/bulk_reject_accounts
    # Rejection is silent by design — registrants get no email.
    def bulk_reject_accounts
      users = pending_selection
      return redirect_with_no_selection if users.empty?

      count = users.size
      users.each { |user| reject!(user) }
      redirect_to review_queue_admin_users_path, notice: "#{count} account(s) were rejected and removed."
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

    private

    def approve!(user)
      user.update!(account_status: :active)
      AccountReviewMailer.account_approved(user).deliver_later
    end

    def reject!(user)
      user.destroy!
    end

    def pending_selection
      User.pending_review.where(id: params[:user_ids])
    end

    def redirect_with_no_selection
      redirect_to review_queue_admin_users_path, alert: "No accounts were selected."
    end

    def display_name(user)
      helpers.strip_tags(user.name.presence || user.email)
    end
  end
end
