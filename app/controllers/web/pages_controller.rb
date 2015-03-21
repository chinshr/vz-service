class Web::PagesController < Web::ApplicationController
  def index
    expires_in rack_cache_time, public: true
    render :layout => "beachstrap"
  end
end
