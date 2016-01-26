class PubSub
  def self.publish(record, data)
    publish_to_channel(record.pubsub_channel, data) if record
  end

  def self.publish_to_channel(channel, data)
    if disabled?
      Rails.logger.info("PUBNUB: #{channel.inspect} #{data.inspect}")
    else
      PUBNUB.publish(
        channel: channel,
        message: data,
        callback: -> (response) {
          code, message, _ = response.parsed_response
          return message if code == 1

          case message
          when "Disconnected"
            raise DisconnectError
          when "Message Too Large"
            raise MessageTooLargeError
          when "Invalid Publish Key"
            raise InvalidPublishKeyError
          when "Invalid Message Signature"
            raise InvalidMessageSignatureError
          else
            raise FailureResponseError
          end
        }
      )
    end
  end

  class FailureResponseError         < StandardError; end
  class DisconnectError              < FailureResponseError; end
  class MessageTooLargeError         < FailureResponseError; end
  class InvalidMessageSignatureError < FailureResponseError; end
  class InvalidPublishKeyError       < FailureResponseError; end

  private

  def self.disabled?
    ENV.fetch('PUBNUB_DISABLED', false)
  end
end
