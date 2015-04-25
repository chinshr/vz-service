require 'aws-sdk-v1'
# prevent threading issues
AWS.eager_autoload!

AWS.config(
  :access_key_id     => APP_CONFIG['S3_KEY'],    # '*** Provide access key ***'
  :secret_access_key => APP_CONFIG['S3_SECRET']  # '*** Provide secret key ***'
)
