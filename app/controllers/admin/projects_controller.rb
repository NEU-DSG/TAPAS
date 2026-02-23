module Admin
  class ProjectsController < Admin::ApplicationController
    # Custom scoped_resource to handle filters via session
    def scoped_resource
      # Store filter state in session
      session[:project_visibility] = params[:visibility] unless params[:visibility].blank?
      session[:project_visibility] = nil if params[:clear_filters]

      resources = super

      # Apply filters based on session state
      case session[:project_visibility]
      when "public"
        resources.where(is_public: true)
      when "private"
        resources.where(is_public: false)
      else
        resources
      end
    end

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
