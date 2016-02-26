class Api::ApplicationController < ::ApplicationController
  include Api::Limit
  include Api::Require

  respond_to :json, :xml

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session

  before_action :set_response_version_header

  rescue_from ActiveRecord::RecordNotFound do |error|
    process_exception(error)
  end

  rescue_from Pundit::NotAuthorizedError do |error|
    process_exception(error)
  end

  rescue_from Api::Exception do |error|
    process_exception(error)
  end

  rescue_from ActionController::ParameterMissing do |error|
    process_exception(error)
  end

  protected

  def api_response(error = nil)
    @api_response || @api_response = Api::Response.new(error)
  end

  def process_exception(error)
    api_response(error)

    # NewRelic & Rails log manual catching error
    Rails.logger.error pretty_exception(error)
    NewRelic::Agent.agent.error_collector.notice_error(error, :request_params => request.params)

    # Note: respond_with doesn't work with PUT request, always return empty
    # respond_with api_response, :status => api_response.http_status || 400
    respond_to do |format|
      format.json { render :json => api_response, :status => api_response.http_status || 400 }
      format.xml  { render :xml => api_response, :status => api_response.http_status || 400 }
    end
  end

  def set_response_version_header
    headers['version'] = Api::Version.to_s
  end

  # Passing version header or parameter returning date object.
  #
  #     curl \
  #     -H 'Authorization: $TOKEN' \
  #     -H 'Accept: application/vnd.vz.api.20150601+json' \
  #     https://www.voyz.es/api/ingests.json?v=20150101
  #
  # or
  #
  #     curl \
  #     -H 'Authorization: $TOKEN' \
  #     https://www.voyz.es/api/ingests.json?v=20150101
  #
  def request_version
    default_version = Date.today.strftime("%Y%m%d")
    pattern = /application\/vnd\.vz\.api\.([\d\.]+)\+.*/
    date_string = params[:v] || request.env['HTTP_ACCEPT'][pattern, 1] || default_version
    Date.parse(date_string)
  rescue ArgumentError
    Date.parse(default_version)
  end

  def count_params
    params.except(:limit, :offset, :sort_order, :reverse_sort)
  end

end
