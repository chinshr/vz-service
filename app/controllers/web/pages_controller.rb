class Web::PagesController < Web::ApplicationController
  def index
    render :layout => "beachstrap"
  end
end
