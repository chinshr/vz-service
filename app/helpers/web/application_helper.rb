module Web::ApplicationHelper
  MARKDOWN_OPTIONS = {:autolink => true, :space_after_headers => true, :fenced_code_blocks => true}
  FAMOUS_QUOTES = [
    ["Shoot for the moon. Even if you miss, you'll land among the stars.", "Les Brown"],
    ["Ignore people who say it can't be done.", "Elaine Rideout"],
    ["Don't let anyone steal your dream. It's your dream, not theirs.", "Dan Zadra"],
    ["The two most important days in your life are the day you are born and the day you find out why.", "Mark Twain"],
    ["Life is what happens to you while you’re busy making other plans.", "John Lennon"],
    ["We become what we think about.", "Earl Nightingale"],
    ["Your time is limited, so don't waste it living someone else's life.", "Steve Jobs"],
    ["The only way to do great work is to love what you do.", "Steve Jobs"],
    ["Everything you've ever wanted is on the other side of fear.", "George Addair"],
    ["Start where you are. Use what you have. Do what you can.", "Arthur Ashe"],
    ["When I let go of what I am, I become what I might be.", "Lao Tzu"],
    ["Too many of us are not living our dreams because we are living our fears.", "Les Brown"],
    ["I would rather die of passion than of boredom.", "Vincent van Gogh"],
    ["Build your own dreams, or someone else will hire you to build theirs.", "Farrah Gray"],
    ["Remember that not getting what you want is sometimes a wonderful stroke of luck.", "Dalai Lama"],
    ["Our lives begin to end the day we become silent about things that matter.", "Martin Luther King Jr."],
    ["Do what you can, where you are, with what you have.", "Teddy Roosevelt"],
    ["If you do what you've always done, you'll get what you've always gotten.", "Tony Robbins"],
    ["The question isn't who is going to let me; it's who is going to stop me.", "Ayn Rand"],
    ["It's not the years in your life that count. It's the life in your years.", "Abraham Lincoln"],
    ["Failure is the condiment that gives success its flavor.", "Truman Capote"],
    ["If you can dream it, you can achieve it.", "Zig Ziglar"],
    ["Pull the string, and it will follow you wherever. Push it, and it will go nowhere at all.", "Dwight Eisenhower"],
    ["Folks, you cannot un-invent things.", "Karlheinz Brandenburg"],
    ["Never give up. You only get one life. Go for it!", "Richard E. Grant"],
    ["At least once a day, allow yourself the freedom to think and dream for yourself.", "Albert Einstein"],
    ["Strive not to be a success, but rather to be of value.", "Albert Einstein"],
    ["Logic will get you from A to B. Imagination will take you everywhere.", "Albert Einstein"],
    ["The true sign of intelligence is not knowledge but imagination.", "Albert Einstein"],
    ["Weakness of attitude becomes weakness of character.", "Albert Einstein"],
    ["The only source of knowledge is experience.", "Albert Einstein"],
    ["The monotony and solitude of a quiet life stimulates the creative mind.", "Albert Einstein"],
    ["Peace cannot be kept by force; it can only be achieved by understanding.", "Albert Einstein"],
    ["A person who never made a mistake, never tried anything new.", "Albert Einstein"],
    ["First learn the meaning of what you say, and then speak.", "Epictetus"]
  ]

  def markdown(text)
    markdown = Redcarpet::Markdown.new(HTMLWithCoderay, MARKDOWN_OPTIONS)
    markdown.render(text).html_safe
  end

  def privacy_policy_from_markdown
    markdown(File.read(Rails.root + "doc/PRIVACY-POLICY.md"))
  end

  def terms_of_service_from_markdown
    markdown(File.read(Rails.root + "doc/TERMS-OF-SERVICE.md"))
  end

  def faqs_from_markdown
    markdown(File.read(Rails.root + "doc/FAQS.md"))
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
      if File.exist?(Rails.root.join("app", "views", path.join("/"), "_#{file}.html.erb"))
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
    key = key.blank? ? "" : (modifiers.blank? ? "(#{key.to_s})" : "(#{modifiers}+#{key})")
    "#{string.to_s.humanize} #{key}".html_safe
  end

  def use_account_split_view?
    controller.is_a?(Web::Account::ApplicationController) && !controller.is_a?(Web::Account::DashboardsController)
  end

  def default_avatar_url(user)
    gender = ["m", "f"][user.id % 1]
    "#{root_url}assets/av/#{gender}#{((user.id % 8) + 1).to_s.rjust(2, "0")}.png"
  end

  def https?
    !!request.protocol.match(/^https/i)
  end

  def avatar_url(user, options = {})
    if user.avatar_url.present?
      user.avatar_url
    else
      # gravatar doc: https://en.gravatar.com/site/implement/images/
      # default avatars: http://www.iconarchive.com/show/face-avatars-icons-by-hopstarter/Male-Face-D1-icon.html
      options.reverse_merge!({size: 96, default_url: default_avatar_url(user)})
      gravatar_id   = Digest::MD5::hexdigest(user.email).downcase
      gravatar_root = https? ? "https://secure.gravatar.com/" : "http://gravatar.com/"
      if false && Rails.env.development?
        options[:default_url]
      else
        #"#{gravatar_root}avatar/#{gravatar_id}.png?s=#{options[:size]}&d=#{CGI.escape(options[:default_url])}"
        "#{gravatar_root}avatar/#{gravatar_id}.png?s=#{options[:size]}&d=identicon"
      end
    end
  end

  def notifier_type_from(key)
    case key.to_s
    when /notice/i then 'info'      # blue
    when /success/i then 'success'  # green
    when /error/i then 'danger'     # red
    when /alert/i then 'warning'    # yellow
    else
      'warning'
    end
  end

  def page_title(caption, with_brand_name = true)
    caption += " — VOYZ.ES" if with_brand_name
    content_for(:title, caption)
  end

  def plan_name(plan)
    name = plan.name.to_s
    name[0].upcase + name[1..-1]
    name
  end

  def plan_plan_name(plan)
    name = plan.name.to_s
    name[0].upcase + name[1..-1]
    "#{name} plan"
  end

  def plan_price(plan, options = {})
    options = {precision: 0}.merge(options)
    number_to_currency(plan.amount / 100.0, options)
  end

  def plan_interval(plan)
    interval = %w(month year week 6-month 3-month).include?(plan.interval) ? plan.interval.delete('-') : 'month'
    I18n.t("pricing.plan_intervals.#{interval}")
  end

  def plan_order(index)
    (index || 0) + 1
  end

  def plan_human_order(index)
    plan_order(index).humanize(locale: :en)
  end

  def plan_display_order(plan)
    plan.display_order || 1
  end

  def plan_human_display_order(plan)
    (plan.display_order || 1).humanize(locale: :en)
  end

  def plan_highlight(plan)
    if plan && plan.highlight
      I18n.t("pricing.plan_highlight.#{plan.highlight}")
    end
  end

  def plan_split_features(plan)
    re = /([\n\n]+)|([\r\n]+)/
    features = plan.features.to_s.split(re).map {|e| e.gsub(re, "")}.reject(&:blank?)
    features.map {|e| yield e} if block_given?
    features
  end

  def month_collection_for_select
    12.times.map {|i| [I18n.l(Date.parse("16/#{i + 1}/1"), format: "%b") + " (#{(i + 1).to_s.rjust(2, "0")})", i + 1] }
  end

  def year_collection_for_select
    current_year = Time.zone.now.year
    exp_year = current_year + 10
    (current_year..exp_year).map {|y| ["#{y}", y]}
  end

  def subscription_payment_type(subscription)
    subscription.card_type
  end

  def subscription_card_number(subscription)
    "**** **** **** #{subscription.card_last4}"
  end

  def subscription_card_expiration(subscription)
    l(subscription.card_expiration, format: "%m/%Y")
  end

  def subscription_plan_interval(subscription)
    plan_interval(subscription.plan)
  end

  def subscription_next_payment_due_on(subscription)
    l(subscription.current_period_end, format: "%Y-%m-%d")
  end

  def subscription_price(subscription, options = {})
    options = {precision: 0}.merge(options)
    number_to_currency(subscription.amount / 100.0, options)
  end

  def subscription_plan_name(subscription)
    plan = subscription.plan
    if plan
      name = plan.name.to_s
      name[0].upcase + name[1..-1]
      "#{name} plan"
    end
  end

  def subscription_plan_user_seats(subscription)
    "1 user"
  end

  def button_to_cancel_subscription(body, html_options = {})
    url = web_account_billing_subscription_path
    capture do
      form_for current_subscription, as: 'subscription', url: url, html: {method: :delete, role: 'form'} do |f|
        hidden_field_tag(:guid, current_subscription.guid) +
        f.submit(body, html_options)
      end
    end
  end

  def button_to_account_plan_sign_up_or_change(plan, options = {}, html_options = {})
    body, url, form_method = nil, nil, :post
    show_account = !!options[:show_account]
    html_options[:class] ||= "btn popup-with-zoom-anim"
    html_options[:disabled] ||= 'disabled' if options[:disabled]

    if current_subscription.nil?
      if current_user
        body = "Upgrade"
        url = new_web_account_billing_payment_method_path(plan_id: plan.uid)
      else
        body = "Sign up"
        url = new_user_registration_path(plan_id: plan.uid)
      end
      # link
      link_to(body, url, html_options)
    elsif current_subscription.persisted?
      if current_user
        url = web_account_billing_subscription_path
        form_method = :put
        if current_subscription.plan == plan && !current_subscription.cancel_at_period_end
          body = "Current"
          html_options[:disabled] = 'disabled'
        elsif current_subscription.plan.display_order > plan.display_order
          body = "Downgrade"
          html_options[:data] = {confirm: "Are you sure you want to downgrade to a #{plan_plan_name(plan)}?"} if options[:confirm]
        else
          body = "Upgrade"
          html_options[:data] = {confirm: "Are you sure you want to upgrade to a #{plan_plan_name(plan)}?"} if options[:confirm]
        end
      else
        # case does not exist
      end
      # form
      capture do
        form_for current_subscription, as: 'subscription', url: url, html: {method: form_method, role: 'form'} do |f|
          hidden_field_tag(:plan_id, plan.uid) +
          hidden_field_tag(:plan_class, plan.plan_class) +
          hidden_field_tag(:quantity, 1) +
          f.submit(body, html_options)
        end
      end
    end
  end

  def sale_tag(sale)
    fa_tag, color = "fa-check", "green"
    if sale.finished? || sale.refunded?
      fa_tag, color = "fa-check", "green"
    else
      fa_tag, color = "fa-times", "red"
    end
    %(<i class="fa #{fa_tag}" style="color: #{color};"></i>).html_safe
  end

  def sale_date(sale, options = {})
    l(sale.created_at, format: :short)
  end

  def sale_price(sale, options = {})
    options = {precision: 0}.merge(options)
    number_to_currency(sale.amount / 100.0, options)
  end

  def sale_name(sale)
    if sale.product && sale.product.is_a?(Plan)
      "#{plan_name(sale.product)} plan"
    end
  end

  def sale_description(sale)
    if sale.product && sale.product.is_a?(Plan)
      "#{plan_name(sale.product)} plan"
    end
  end

  def sale_payment_type(sale)
    sale.card_type
  end

  def sale_payment_method_description(sale)
    %(<i class="fa fa-credit-card fa-right-padding"></i>#{sale_payment_type(sale)} ending in #{sale.card_last4}).html_safe
  end
end
