class Api::Exception < Exception

  attr_accessor :code, :http_status, :message

  def initialize(message = nil, code = nil)
    @code        = code || Api::Code::UNKNOWN
    @message     = message || Api::Code.get_message(@code)
    @http_status = Api::Code.get_http_status(@code)
  end

  def inspect
    "code:#{code} message:#{message.to_s}"
  end

  alias :to_s :inspect # New Relic relies on #to_s to gather its exception message.
end