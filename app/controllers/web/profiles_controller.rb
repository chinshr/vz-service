class Web::ProfilesController < Web::ApplicationController

  def show
    raise ActionController::RoutingError.new('Not Found')
  end

end
