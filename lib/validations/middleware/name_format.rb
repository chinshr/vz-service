class ::ClientSideValidations::Middleware::NameFormat < ClientSideValidations::Middleware::Base
  def response
    if value = request.params[:name] || request.params[:first_name] || request.params[:last_name]
      unless value =~ NameFormatValidator::REGEXP
        self.status = 422
      else
        self.status = 200
      end
    end
    super
  end
end
