require 'pubnub'

PUBNUB = Pubnub.new(
  publish_key: APP_CONFIG['PUBNUB_PUBLISH_KEY'] || 'demo',
  subscribe_key: APP_CONFIG['PUBNUB_SUBSCRIBE_KEY'] || 'demo',
  # logger: Logger.new(nil),
  error_callback: -> (msg) {
    puts "ERROR: #{msg.inspect}"
  },
  connect_callback: -> (msg) {
    puts "CONNECTED: #{msg.inspect}"
  }
)
