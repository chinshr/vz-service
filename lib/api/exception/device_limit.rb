class Api::Exception::DeviceLimit < Api::Exception
  def initialize(message = nil)
    super(message, Api::Code::DEVICE_LIMIT)
  end
end