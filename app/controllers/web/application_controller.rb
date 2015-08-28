class Web::ApplicationController < ApplicationController
  helper Web::ApplicationHelper

  respond_to :html

  rescue_from Pundit::NotAuthorizedError do |error|
    process_unauthorized_exception(error)
  end

  protected

  def rack_cache_time
    disable_rack_cache_request? ? 0.seconds : 5.minutes
  end

  def disable_rack_cache_request?
    # !!(request.env["HTTP_HOST"] && request.env["HTTP_HOST"].match(/voyzes\.herokuapp\.com/)) ||
    # !!(request.env['HTTP_X_FORWARDED_HOST'] && env['HTTP_X_FORWARDED_HOST'].match(/voyzes\.herokuapp\.com/)) ||
    Rails.env.development? || Rails.env.test?
  end

  def process_unauthorized_exception(error)
    # NewRelic & Rails log manual catching error
    Rails.logger.error pretty_exception(error)
    NewRelic::Agent.agent.error_collector.notice_error(error, :request_params => request.params)

    respond_to do |format|
      format.html { render layout: nil, file: "public/401.html", status: :unauthorized }
    end
  end

end
