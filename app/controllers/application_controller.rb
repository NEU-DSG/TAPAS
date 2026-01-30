class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?

  helper Openseadragon::OpenseadragonHelper

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

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
