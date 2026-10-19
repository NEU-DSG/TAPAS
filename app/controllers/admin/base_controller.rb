# Parent for every admin controller. Admin pages inherit the app's own
# controller stack, so they load JavaScript through the same importmap as
# public pages.
module Admin
  class BaseController < ::ApplicationController
    include Admin::ResourceIndex

    layout "admin/application"

    before_action :authenticate_admin

    private

    def authenticate_admin
      authenticate_user!
      redirect_to root_path, alert: "Access denied." unless current_user.admin?
    end

    # Admin forms always show the nested image fields. Leaving them all empty
    # means "no image"; passing them through would try to create a blank
    # ImageFile and fail validation.
    def without_blank_image_file(attributes)
      image = attributes[:image_file_attributes]
      return attributes if image.nil? || image[:id].present?
      return attributes if image.except(:_destroy).values.any?(&:present?)

      attributes.except(:image_file_attributes)
    end
  end
end
