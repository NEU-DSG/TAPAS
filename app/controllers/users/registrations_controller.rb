# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  # POST /resource
  def create
    super do |resource|
      session[:new_registration] = true if resource.persisted?
    end
  end

  # DELETE /resource
  def destroy
    blocking_projects = current_user.sole_owned_projects
    if blocking_projects.any?
      respond_to do |format|
        format.html do
          redirect_to edit_user_registration_path,
            alert: "Account cannot be deleted while you are the sole owner of: #{blocking_projects.map(&:title).to_sentence}. Transfer ownership or delete those projects first."
        end
        format.json do
          render json: {
            error: "Account cannot be deleted while you are the sole owner of one or more projects.",
            projects: blocking_projects.map { |p| { id: p.id, title: p.title } }
          }, status: :unprocessable_content
        end
      end
      return
    end

    super
  end
end
