class ::ClientSideValidations::Middleware::Registration < ClientSideValidations::Middleware::Base
  def response
    if ::Registration.accepted.where(email: request.params[:id]).exists?
      self.status = 200
    else
      self.status = 404
    end
    super
  end
end