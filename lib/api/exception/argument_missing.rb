class Api::Exception::ArgumentMissing < Api::Exception

  def initialize(message = nil)
    if message.is_a?(Symbol)
      message = I18n.t('api.error_code.argument_missing_name', :argument_name => message)
    end
    super(message, Api::Code::ARGUMENT_MISSING)
  end

end