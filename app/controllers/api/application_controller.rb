class Api::ApplicationController < ApplicationController
  include Api::Limit
  include Api::Require
  include Api::ApplicationHelper
  helper Api::ApplicationHelper

  #before_action :authenticate_user_from_token!
  #before_action :authenticate_user!

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session

  respond_to :json, :xml

  before_filter :version_header

  rescue_from ActiveRecord::RecordNotFound do |exception|
    process_exception(exception)
  end

  rescue_from Pundit::NotAuthorizedError do |exception|
    process_exception(exception)
  end

  rescue_from Api::Exception do |exception|
    process_exception(exception)
  end

  rescue_from ActionController::ParameterMissing do |exception|
    process_exception(exception)
  end

  protected

  def api_response(error = nil)
    @api_response || @api_response = Api::Response.new(error)
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

  # authentication_secret = SecureRandom.urlsafe_base64(nil, false)
  #
  # 1. Create `access_id` (hashed email) in User table
  #
  # 2. `access_secret` random hash in User table
  #
  # 3. API user is authenticating with
  #
  #     &token=<access-id> + ':' + <hexdigest(access_secret)>
  #
  # Note: In the user's account section we will provide that token
  # prepared to be consumed.
  #
  # 4. Server looks up User by `access_id`
  #
  # 5. Reject user if not of role 'backend' or 'developer'.
  #
  # 5. Compares user's hexdigest(access_secret) with User access_secret, the
  #    (2nd) portion of the token.
  #
  #    &token = <access_id>:<hexdigest_access_secret>
  #
  def authenticate_user_from_token!
    binding.pry if headers['Authorization']
    if access_token = params[:token].presence || headers['Authorization'].presence
      access_id, access_secret = access_token.try(:split, ':')
      user = access_id && access_secret && User.find_by(access_id: access_id)
      # Notice how we use Devise.secure_compare to compare the token
      # in the database with the token given in the params, mitigating
      # timing attacks.
      if user && user.roles.any? {|r| [:backend, :developer].include?(r)} && user.secure_compare_access_secret(access_secret)
        sign_in user, store: false
      else
        raise Api::Exception::AuthorizationError.new(I18n.t('api.error_code.authorization_error.platform'))
      end
    end
  end

end
