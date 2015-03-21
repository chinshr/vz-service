class Web::ApplicationController < ApplicationController
  helper Web::ApplicationHelper

  respond_to :html

  rescue_from Pundit::NotAuthorizedError do
    render :file => "public/401.html", :status => :unauthorized
  end

  protected

  def rack_cache_time
    disable_rack_cache_request? ? 0.seconds : 5.minutes
  end

  def disable_rack_cache_request?
    !!(request.env["HTTP_HOST"] && request.env["HTTP_HOST"].match(/voyzes\.herokuapp\.com/)) ||
    !!(request.env['HTTP_X_FORWARDED_HOST'] && env['HTTP_X_FORWARDED_HOST'].match(/voyzes\.herokuapp\.com/)) ||
    Rails.env.development? || Rails.env.test?
  end


end
