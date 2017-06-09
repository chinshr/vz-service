class ::ClientSideValidations::Middleware::UsernameFormat < ClientSideValidations::Middleware::Base
  def response
    if value = request.params[:username]
      unless value =~ UsernameFormatValidator::REGEXP
        self.status = 422
      else
        self.status = 200
      end
    end
    super
  end
end
