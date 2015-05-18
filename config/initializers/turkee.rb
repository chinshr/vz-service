# Go to this page https://aws-portal.amazon.com/gp/aws/developer/account/index.html?action=access-key
# to retrieve your AWS/Mechanical Turk access keys.

RTurk::logger.level = Logger::DEBUG
RTurk.setup(APP_CONFIG['S3_KEY'], APP_CONFIG['S3_SECRET'], :sandbox => (Rails.env == 'production' ? false : true))