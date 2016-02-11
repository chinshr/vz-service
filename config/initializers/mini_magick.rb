MiniMagick.configure do |config|
  config.cli                = :imagemagick # :graphicsmagick
  config.timeout            = 5
  config.debug              = Rails.env.development?
#  config.logger             = Rails.logger
  config.whiny              = false # true
  config.validate_on_create = true
  config.validate_on_write  = true
end