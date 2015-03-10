class Web::Account::ApplicationController < Web::ApplicationController
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
end
