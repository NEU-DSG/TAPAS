# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  # DELETE /resource
  def destroy
    blocking_projects = current_user.sole_owned_projects
    if blocking_projects.any?
      render json: {
        error: "Account cannot be deleted while you are the sole owner of one or more projects.",
        projects: blocking_projects.map { |p| { id: p.id, title: p.title } }
      }, status: :unprocessable_content
      return
    end

    super
  end
end
