module ApplicationHelper
  MARKDOWN_OPTIONS = {:autolink => true, :space_after_headers => true, :fenced_code_blocks => true}

  def markdown(text)
    markdown = Redcarpet::Markdown.new(HTMLWithCoderay, MARKDOWN_OPTIONS)
    markdown.render(text).html_safe
  end

  def readme_to_markdown
    markdown(File.read(Rails.root + "README.md"))
  end
  
  # E.g. devise sessions
  def dom_controller_class
    controller.class.name.split("::").map {|e| e.gsub("Controller", "").underscore.dasherize}.join(" ")
  end
  
  # E.g. new-user
  def dom_controller_action_class
    action_name.dasherize
  end
  
  def multi_tenant?
    ENV.key?("MULTI_TENANT") ? ENV["MULTI_TENANT"] == "true" : true
  end
  
  def dom_active_class(current_controller)
    controller.is_a?(current_controller) ? "active" : ""
  end
  
  def dom_alert_class(key)
    case key.to_s
    when "alert" then "danger"
    else
      key
    end
  end
  
  def account_controller?
    controller.is_a?(Web::Account::ApplicationController) ||
      controller.is_a?(Doorkeeper::ApplicationsController)
  end
end
