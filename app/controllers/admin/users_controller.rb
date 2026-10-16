module Admin
  class UsersController < Admin::BaseController
    # Search is limited to these columns so an admin search can never match
    # against password hashes or reset-token digests.
    admin_index search: %i[email name institution],
                sort: %i[email name institution admin_at sign_in_count created_at],
                filters: {
                  admin: ->(users) { users.where.not(admin_at: nil) },
                  active: ->(users) { users.where("sign_in_count > 0") }
                }

    before_action :set_user, only: %i[show edit update destroy]

    def index
      @users = index_resources(User.all)
    end

    def show
    end

    def new
      @user = User.new
    end

    def edit
    end

    def create
      @user = User.new(user_params)

      if @user.save
        redirect_to [ :admin, @user ], notice: "User was successfully created."
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      if @user.update(user_params)
        redirect_to [ :admin, @user ], notice: "User was successfully updated.", status: :see_other
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      if @user.destroy
        redirect_to admin_users_path, notice: "User was successfully destroyed.", status: :see_other
      else
        redirect_to [ :admin, @user ], alert: @user.errors.full_messages.to_sentence, status: :see_other
      end
    end

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

    private

    def set_user
      @user = User.find(params.expect(:id))
    end

    def user_params
      without_blank_image_file(params.expect(user: [
        :account_status, :email, :name, :bio, :institution, :admin_at,
        image_file_attributes: [ :id, :title, :description, :image_url, :file_format, :depositor_id, :_destroy ]
      ]))
    end

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
