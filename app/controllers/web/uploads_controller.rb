class Web::UploadsController < ApplicationController
  
  def show
  end
  
  def signput
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Credentials'] = 'true'
    response.headers['Access-Control-Allow-Methods'] = 'OPTIONS, GET, POST'
    response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Depth, User-Agent, X-File-Size, X-Requested-With, If-Modified-Since, X-File-Name, Cache-Control'

    object_name = "/#{params['name']}"

    mime_type = params['type']
    expires = Time.now.to_i + APP_CONFIG['EXPIRE_TIME']

    amz_headers = "x-amz-acl:public-read"
    string_to_sign = "PUT\n\n#{mime_type}\n#{expires}\n#{amz_headers}\n#{APP_CONFIG['S3_BUCKET']}#{object_name}"
    sig = CGI::escape(Base64.strict_encode64(OpenSSL::HMAC.digest('sha1', APP_CONFIG['S3_SECRET'], string_to_sign)))

    render :text => CGI::escape("#{APP_CONFIG['S3_URL']}#{APP_CONFIG['S3_BUCKET']}#{object_name}?AWSAccessKeyId=#{APP_CONFIG['S3_KEY']}&Expires=#{expires}&Signature=#{sig}")
  end
  
end
