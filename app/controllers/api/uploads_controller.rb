class Api::UploadsController < Api::ApplicationController
  before_filter :cors_allow_origin, :only => :signput
  
  # [POST] /api/uploads.json
  def create
    ActiveSupport::Deprecation.warn("Should be replaced with [POST] /api/accounts/uploads.json")
    @upload = Upload.new(create_params.permit(:type)) do |u|
      u.session_id = current_session.id if current_session
    end
    @upload.attributes = create_params.except(:type)
    @upload.save
    respond_with "api", @upload
  end

  # [GET] /api/uploads.json
  def index
    ActiveSupport::Deprecation.warn("Should be replaced with [GET] /api/accounts/uploads.json")
    @uploads = current_session.uploads.any_of_states(:foobar) if current_session
    respond_with @uploads
  end

  # [GET] /api/uploads/1.json
  def show
    ActiveSupport::Deprecation.warn("Should be replaced with [GET] /api/accounts/uploads/1.json")
    @upload = Upload.find(params[:id])
    respond_with @upload
  end

  # [PUT] /api/uploads/1.json
  def update
    ActiveSupport::Deprecation.warn("Should be replaced with [PUT] /api/accounts/uploads/1.json")
    @upload = Upload.update(params[:id], update_params)
    respond_with @upload
  end

  # [DELETE] /api/uploads/1.json
  def destroy
    ActiveSupport::Deprecation.warn("Should be replaced with [DELETE] /api/accounts/uploads/1.json")
    respond_with Upload.destroy(params[:id])
  end
  
  def signput
    ActiveSupport::Deprecation.warn("Should be replaced with [GET] /api/accounts/uploads/signput.json")
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

  def cors_allow_origin
    response.headers['Access-Control-Allow-Origin']      = '*'
    response.headers['Access-Control-Allow-Credentials'] = 'true'
    response.headers['Access-Control-Allow-Methods']     = 'OPTIONS, GET, POST'
    response.headers['Access-Control-Allow-Headers']     = 'Content-Type, Depth, User-Agent, X-File-Size, X-Requested-With, If-Modified-Since, X-File-Name, Cache-Control'
  end

  def create_params
    params.require(:upload).permit(:type, :file_name, :file_type, :file_size, :s3_url, :locale, :privacy)
  end

  def update_params
    params.require(:upload).permit(:title, :description, :tag_list, :locale, :privacy)
  end
end
