class Api::ApplicationController < ApplicationController
  include Api::ApplicationHelper
  helper Api::ApplicationHelper
  
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session
  
  respond_to :json, :xml

  before_filter :version_header
  
  rescue_from ActiveRecord::RecordNotFound do |exception|
    # process_exception(Api::Exception::RecordNotFound.new)
    process_exception(exception)
  end
  
  protected
  
  def api_response(data = nil)
    @api_response || @api_response = Api::Response.new(data)
  end
  
  def process_exception(exception)
    api_response(exception)
    
    # NewRelic & Rails log manual catching error 
    Rails.logger.error pretty_exception(exception)
    NewRelic::Agent.agent.error_collector.notice_error(exception, :request_params => request.params)

    # Note: respond_with doesn't work with PUT request, always return empty
    # respond_with api_response, :status => api_response.http_status || 400
    respond_to do |format|
      format.json { render :json => api_response, :status => api_response.http_status || 400 }
      format.xml  { render :xml => api_response, :status => api_response.http_status || 400 }
    end
  end
  
  def version_header
    headers['version'] = Api::Version.to_s
  end
  
end
