module ClientSideValidations::Middleware
  class Registration < ClientSideValidations::Middleware::Base
    def response
      puts "-->> Entry!"
      if ::Registration.accepted.where(email: request.params[:id]).exists?
        self.status = 200
      else
        self.status = 404
      end
      puts "-->> super"
      super
    end
  end
end