class Web::ApplicationController < ApplicationController
  helper Web::ApplicationHelper

  respond_to :html

  rescue_from Pundit::NotAuthorizedError do
    render :file => "public/401.html", :status => :unauthorized
  end
end
