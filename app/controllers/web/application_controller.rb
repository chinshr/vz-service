class Web::ApplicationController < ApplicationController
  helper Web::ApplicationHelper
  
  rescue_from Pundit::NotAuthorizedError do
    render :file => "public/401.html", :status => :unauthorized
  end
end
