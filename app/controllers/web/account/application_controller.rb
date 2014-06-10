class Web::Account::ApplicationController < Web::ApplicationController
  before_filter :authenticate_user!
  before_filter :redirect_to_dashboard
  
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
end
