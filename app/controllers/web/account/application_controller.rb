class Web::Account::ApplicationController < Web::ApplicationController
  include Payola::StatusBehavior
  include PaymentBehavior

  before_filter :authenticate_user!
  before_filter :redirect_to_dashboard
  after_filter :flash_to_headers

  def index
    redirect_to web_dashboard_path, status: :moved_permanently
  end

  protected

  def redirect_to_dashboard
    if self.class == Web::Account::ApplicationController && warden && current_user
      redirect_to web_dashboard_path, status: :moved_permanently
      return false
    end
  end

  def flash_to_headers
    return unless request.xhr?
    if tm = flash_type_and_message
      response.headers["X-Message-Type"] = tm.first
      response.headers['X-Message']      = tm.last
    end
    #flash.discard # don't want the flash to appear when you reload page
  end

  def flash_type_and_message
    flash.each do |key, message|
      return key, message
    end
    nil
  end

  # Sets the flash message with :key, using I18n. By default you are able
  # to setup your messages using specific resource scope, and if no one is
  # found we look to default scope.
  # Example (i18n locale file):
  #
  #   en:
  #     devise:
  #       passwords:
  #         #default_scope_messages - only if resource_scope is not found
  #         user:
  #           #resource_scope_messages
  #
  # Please refer to README or en.yml locale file to check what messages are
  # available.
  def set_flash_message(key, kind, options = {})
    message = find_resource_message(kind, options)
    flash[key] = message if message.present?
  end

  # Get message for given
  def find_resource_message(kind, options = {})
    options[:scope]         = "devise.registrations"
    options[:default]       = Array(options[:default]).unshift(kind.to_sym)
    options[:resource_name] = resource_name.underscore
    options = devise_i18n_options(options) if respond_to?(:devise_i18n_options, true)
    I18n.t("#{options[:resource_name]}.#{kind}", options)
  end

  def resource_name
    "User"
  end
end
