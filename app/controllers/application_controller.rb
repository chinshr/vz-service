class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  include ApplicationHelper

  protected

  def after_sign_in_path_for(resource)
    if resource.is_a?(User)
      web_dashboard_path
    else
      admin_dashboard_path
    end
  end

  def devise_parameter_sanitizer
    if resource_class == User
      User::ParameterSanitizer.new(User, :user, params)
    else
      super
    end
  end

  def load_document
    @document = Document.eager_load_associations.params_id(params).first!
  end
end
