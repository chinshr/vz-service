module Web::ApplicationHelper
  MARKDOWN_OPTIONS = {:autolink => true, :space_after_headers => true, :fenced_code_blocks => true}
  FAMOUS_QUOTES = [
    ["Shoot for the moon. Even if you miss, you'll land among the stars.", "Les Brown"],
    ["It's the possibility of having a dream come true that makes life interesting.", "Paulo Coelho"],
    ["Ignore people who say it can't be done.", "Elaine Rideout"],
    ["Don't let anyone steal your dream. It's your dream, not theirs.", "Dan Zadra"],
    ["At least once a day, allow yourself the freedom to think and dream for yourself.", "Albert Einstein"],
    ["The two most important days in your life are the day you are born and the day you find out why.", "Mark Twain"],
    ["Strive not to be a success, but rather to be of value.", "Albert Einstein"],
    ["Life is what happens to you while you’re busy making other plans.", "John Lennon"],
    ["We become what we think about.", "Earl Nightingale"],
    ["Your time is limited, so don't waste it living someone else's life.", "Steve Jobs"],
    ["Everything you've ever wanted is on the other side of fear.", "George Addair"],
    ["Start where you are. Use what you have. Do what you can.", "Arthur Ashe"],
    ["When I let go of what I am, I become what I might be.", "Lao Tzu"],
    ["Too many of us are not living our dreams because we are living our fears.", "Les Brown"],
    ["A person who never made a mistake never tried anything new.", "Albert Einstein"],
    ["I would rather die of passion than of boredom.", "Vincent van Gogh"],
    ["Build your own dreams, or someone else will hire you to build theirs.", "Farrah Gray"],
    ["Remember that not getting what you want is sometimes a wonderful stroke of luck.", "Dalai Lama"],
    ["Our lives begin to end the day we become silent about things that matter.", "Martin Luther King Jr."],
    ["Do what you can, where you are, with what you have.", "Teddy Roosevelt"],
    ["If you do what you've always done, you'll get what you've always gotten.", "Tony Robbins"],
    ["The question isn't who is going to let me; it's who is going to stop me.", "Ayn Rand"],
    ["It's not the years in your life that count. It's the life in your years.", "Abraham Lincoln"],
    ["The only way to do great work is to love what you do.", "Steve Jobs"],
    ["Failure is the condiment that gives success its flavor.", "Truman Capote"],
    ["If you can dream it, you can achieve it.", "Zig Ziglar"],
    ["Pull the string, and it will follow you wherever. Push it, and it will go nowhere at all.", "Dwight Eisenhower"]
  ]

  def markdown(text)
    markdown = Redcarpet::Markdown.new(HTMLWithCoderay, MARKDOWN_OPTIONS)
    markdown.render(text).html_safe
  end

  def privacy_policy_to_markdown
    markdown(File.read(Rails.root + "PRIVACY-POLICY.md"))
  end

  def terms_of_service_to_markdown
    markdown(File.read(Rails.root + "TERMS-OF-SERVICE.md"))
  end

  # E.g. devise sessions
  def dom_controller_class
    controller.class.name.split("::").map {|e| e.gsub("Controller", "").underscore.dasherize}.join(" ")
  end

  # E.g. new-user
  def dom_controller_action_class
    action_name.dasherize
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

  # E.g.
  #
  #  :bold, 'B', :meta_key
  #  :align, 'A', [:shift_key, :meta_key]
  #
  def key_cmd(string, key = nil, modifiers = nil)
    modifiers = [modifiers].flatten
    modifiers = modifiers.inject([]) do |ms, e|
      # {ctrlKey: false, altKey: false, metaKey: true, shiftKey: true}
      ms << case e
      when :meta_key  then "⌘"
      when :shift_key then "⇧"
      when :alt_key   then "⌥"
      when :ctrl_key  then "⌃"
      end
    end
    modifiers = modifiers.reject(&:blank?).inject('') {|s, m| s += m.to_s}
    key = key.blank? ? "" : (modifiers.blank? ? "(#{key.to_s})" : "(#{modifiers}-#{key})")
    "#{string.to_s.humanize} #{key}".html_safe
  end

  def edit?
    action_name == "edit"
  end

  def show?
    action_name == "show"
  end

  def use_account_split_view?
    controller.is_a?(Web::Account::ApplicationController) && !controller.is_a?(Web::Account::DashboardsController)
  end

  def default_avatar_url(user)
    "#{root_url}images/a#{(user.id % 11).to_s.rjust(2, "0")}.png"
  end

  def avatar_url(user, options = {})
    if user.avatar_url.present?
      user.avatar_url
    else
      options.reverse_merge!({size: 96, default_url: default_avatar_url(user)})
      gravatar_id = Digest::MD5::hexdigest(user.email).downcase
      "//gravatar.com/avatar/#{gravatar_id}.png?s=#{options[:size]}&d=#{CGI.escape(options[:default_url])}"
    end
  end
end