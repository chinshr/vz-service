class Api::Account::UploadsController < Api::Account::ApplicationController
  before_filter :cors_allow_origin, :only => :signput
  
  # [POST] /api/account/uploads(.:format)
  def create
    @upload = Upload.new(create_params.permit(:type)) do |u|
      u.session_id = current_session.id if current_session
    end
    @upload.attributes = create_params.except(:type)
    @upload.user = current_user if current_user
    @upload.save
    respond_with "api", @upload
  end

  # [GET] /api/account/uploads(.:format)
  def index
    debugger
    @uploads = current_user.uploads.filter(params)
    respond_with @uploads
  end

  # [GET] /api/account/uploads/1(.:format)
  def show
    @upload = current_user.uploads.find(params[:id])
    respond_with @upload
  end

  # [PUT] /api/account/uploads/1(.:format)
  def update
    @upload = current_user.uploads.update(params[:id], update_params)
    respond_with @upload
  end

  # [DELETE] /api/account/uploads/1(.:format)
  def destroy
    @upload = current_user.uploads.find(params[:id])
    @upload = Upload.destroy(@upload)
    respond_with @upload
  end
  
  # [GET] /api/account/uploads/signput(.:format)
  def signput
    object_name    = params[:s3_object_name]
    mime_type      = params[:s3_object_type]
    expires        = Time.now.to_i + APP_CONFIG['EXPIRE_TIME'].to_i

    amz_headers    = "x-amz-acl:public-read" # set the public read permission on the uploaded file
    string_to_sign = "PUT\n\n#{mime_type}\n#{expires}\n#{amz_headers}\n#{APP_CONFIG['S3_INBOUND_BUCKET']}/#{object_name}";
    signature      = CGI::escape(Base64.strict_encode64(OpenSSL::HMAC.digest('sha1', APP_CONFIG['S3_SECRET'], string_to_sign)))

    @signput = {
      signed_request: CGI::escape("#{APP_CONFIG['S3_URL']}#{APP_CONFIG['S3_INBOUND_BUCKET']}/#{object_name}?AWSAccessKeyId=#{APP_CONFIG['S3_KEY']}&Expires=#{expires}&Signature=#{signature}"),
      url: "#{APP_CONFIG['S3_URL']}#{APP_CONFIG['S3_INBOUND_BUCKET']}/#{object_name}"
    }

    respond_with @signput
  end
  
  protected

  def create_params
    params.require(:upload).permit(:type, :file_name, :file_type, :file_size, :s3_url, :locale, :privacy)
  end

  def update_params
    params.require(:upload).permit(:title, :description, :locale, :privacy)
  end

  def cors_allow_origin
    response.headers['Access-Control-Allow-Origin']      = '*'
    response.headers['Access-Control-Allow-Credentials'] = 'true'
    response.headers['Access-Control-Allow-Methods']     = 'OPTIONS, GET, POST'
    response.headers['Access-Control-Allow-Headers']     = 'Content-Type, Depth, User-Agent, X-File-Size, X-Requested-With, If-Modified-Since, X-File-Name, Cache-Control'
  end
end
