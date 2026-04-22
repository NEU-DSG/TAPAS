class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?

  rescue_from CanCan::AccessDenied do |exception|
    respond_to do |format|
      format.json { render json: { error: exception.message }, status: :forbidden }
      format.html { redirect_to root_path, alert: exception.message }
    end
  end

  helper Openseadragon::OpenseadragonHelper

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private

  def accessible_collection_ids_for(user)
    user.project_members.flat_map do |pm|
      if pm.project_wide?
        Collection.where(project: pm.project).pluck(:id)
      else
        pm.collection_scopes.pluck(:collection_id)
      end
    end
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [
      :username,
      :email,
      :password,
      :name,
      :institution_id,
      { image_file: [ :file ] },
      :bio,
      :account_type
    ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :username, :email, :password, :password_confirmation, :current_password, :name, :institution_id, { image_file: [ :file ] }, :remove_avatar, :bio, :account_type ])
  end
end
