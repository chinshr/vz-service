class Api::Account::UploadsController < Api::Account::ApplicationController
  include Pundit
  include Api::Authorization

  before_action :authenticate_user!
  before_action :cors_allow_origin, :only => :sign_s3

  # [POST] /api/account/uploads(.:format)
  def create
    authorize :"account/upload"
    @upload = Upload::MediaUpload.create(create_params) do |u|
      u.user = current_user
    end
    respond_with "api", "account", @upload
  end

  # [GET] /api/account/media_uploads(.:format)
  def index
    @uploads = current_user.uploads.filter(params)
    respond_with @uploads
  end

  # [GET] /api/account/media_uploads/count(.:format)
  def count
    render :json => {:count => current_user.uploads.filter(params).count}
  end

  # [GET] /api/account/media_uploads/:id(.:format)
  def show
    @upload = current_user.uploads.find(params[:id])
    respond_with @upload
  end

  # [PUT] /api/account/media_uploads/:id(.:format)
  def update
    authorize :"account/upload"
    @upload = current_user.uploads.update(params[:id], update_params)
    respond_with @upload
  end

  # [DELETE] /api/account/media_uploads/:id(.:format)
  def destroy
    @upload = current_user.uploads.find(params[:id])
    @upload.destroy
    respond_with @upload
  end

  # [GET] /api/account/media_uploads/sign_s3(.:format)
  def sign_s3
    object_name    = params[:s3_object_name]
    mime_type      = params[:s3_object_type]
    expires        = Time.zone.now.to_i + APP_CONFIG['EXPIRE_TIME'].to_i

    amz_headers    = "x-amz-acl:public-read" # set the public read permission on the uploaded file
    string_to_sign = "PUT\n\n#{mime_type}\n#{expires}\n#{amz_headers}\n#{APP_CONFIG['S3_INBOUND_BUCKET']}/#{object_name}";
    signature      = CGI::escape(Base64.strict_encode64(OpenSSL::HMAC.digest('sha1', APP_CONFIG['S3_SECRET'], string_to_sign)))

    @sign_s3 = {
      signed_request: CGI::escape("#{s3_url}#{APP_CONFIG['S3_INBOUND_BUCKET']}/#{object_name}?AWSAccessKeyId=#{APP_CONFIG['S3_KEY']}&Expires=#{expires}&Signature=#{signature}"),
      url: "#{s3_url}#{APP_CONFIG['S3_INBOUND_BUCKET']}/#{object_name}"
    }
    respond_with @sign_s3
  end

  protected

  def create_params
    params.require(:upload).permit(policy(:"account/upload").permitted_attributes(action_name)).tap do |whitelisted|
      whitelisted[:metadata] = params[:upload][:metadata] if params[:upload][:metadata]
    end
  end

  def update_params
    params.require(:upload).permit(policy(:"account/upload").permitted_attributes(action_name))
  end

  def cors_allow_origin
    response.headers['Access-Control-Allow-Origin']      = '*'
    response.headers['Access-Control-Allow-Credentials'] = 'true'
    response.headers['Access-Control-Allow-Methods']     = 'OPTIONS, GET, POST'
    response.headers['Access-Control-Allow-Headers']     = 'Content-Type, Depth, User-Agent, X-File-Size, X-Requested-With, If-Modified-Since, X-File-Name, Cache-Control'
  end

  def s3_url
    uri = URI(APP_CONFIG['S3_URL'])
    uri.scheme = request.ssl? ? 'https' : 'http'
    uri.to_s
  end
end
