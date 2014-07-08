module ApplicationHelper
  MARKDOWN_OPTIONS = {:autolink => true, :space_after_headers => true, :fenced_code_blocks => true}
  FAMOUS_QUOTES = [
    ["Shoot for the moon. Even if you miss, you'll land among the stars.", "Les Brown"],
    ["It's the possibility of having a dream come true that makes life interesting.", "Paulo Coelho, Alchemist"],
    ["Ignore people who say it can't be done.", "Elaine Rideout"],
    ["Don't let anyone steal your dream. It's your dream, not theirs.", "Dan Zadra"],
    ["At least once a day, allow yourself the freedom to think and dream for yourself.", "Albert Einstein"],
    ["Why not go out on a limb? Isn't that where the fruit is?", "Mark Twain"]
  ]

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
  
  def render_header
    render_recursive_partial("header")
  end

  def render_footer
    render_recursive_partial("footer")
  end
  
  def render_recursive_partial(file)
    path = params[:controller].split("/") 
    while !path.empty? do
      if File.exists?(Rails.root.join("app", "views", path.join("/"), "_#{file}.html.erb"))
        return render "#{path.join("/")}/#{file}"
      else
        path.pop
      end
    end
  end
  
  def random_login_quote
    FAMOUS_QUOTES[rand(FAMOUS_QUOTES.size.to_i)]
  end
  
end
