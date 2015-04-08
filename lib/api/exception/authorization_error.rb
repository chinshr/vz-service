class Api::Exception::AuthorizationError < Api::Exception

  def initialize(message = nil)
    # errors should be ActiveModel::Errors class from model errors
    super(message, Api::Code::AUTHORIZATION_ERROR)
  end
end