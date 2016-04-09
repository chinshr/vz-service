class Api::AuthorizationController < Api::ApplicationController
  include Api::Authorization
  before_action :authorize_client!, except: :client_authorize
  before_action :authorize_user!, except: [:client_authorize, :user_authorize, :status]

  # > [POST] /api/authorize/client(.:format)?client_key=<client-key>&device_uid=<device-uid>
  # < {access_token: "abc...", access_secret: "efg..."}
  def client_authorize
    raise Api::Exception::ArgumentMissing.new(:client_key) unless params.has_key?(:client_key)
    raise Api::Exception::ArgumentMissing.new(:device_uid) unless params.has_key?(:device_uid)

    client = Api::Client.find_by!(key: params[:client_key])
    client_access = client.client_accesses.create(device_uid: params[:device_uid],
      :access_status => Api::ClientAccess::ACCESS_STATUS_CLIENT)
    client_access.kill_clones

    respond_with Api::Response.new(access_token: client_access.uid,
      access_secret: client_access.access_secret), location: api_authorization_client_authorize_url
  end

  # [POST] /api/authorize/user(.:format)?email=<user-email>&password=<user-password>&access_token=<access_token>
  def user_authorize
    raise Api::Exception::ArgumentMissing.new(:email) unless params[:email]
    raise Api::Exception::ArgumentMissing.new(:password) unless params[:password]

    user = User.find_by!(email: params[:email])
    raise Api::Exception::AuthorizationError.new unless user.valid_password?(params[:password]) && user.active?
    current_access.sign_in(user)
    sign_in user, store: false
    current_access.kill_clones

    respond_with(Api::Response.new, location: api_authorization_user_authorize_url)
  end

  # [GET] /api/authorize/status(.:format)?access_token=<access-token>
  def status
    api_response = Api::Response.new(:access_status => current_access.access_status, :updated_at => current_access.updated_at)
    respond_with(api_response, location: api_authorization_status_url)
  end

  # [DELETE] /api/authorize/user(.:format)?access_token=<access_token>
  def user_deauthorize
    current_access.update_attributes(user_id: nil, access_status: Api::ClientAccess::ACCESS_STATUS_CLIENT)
    respond_with(Api::Response.new(:access_status => current_access.access_status, :updated_at => current_access.updated_at),
      location: api_authorization_user_deauthorize_url)
  end

end
