class Web::RegistrationsController < Web::ApplicationController

  def create
    @registration = Registration.instance_for(params[:registration], 
      request.location.data, 
      {
        :locale     => I18n.locale,
        :ip_address => request.remote_ip
      })
    @registration.save
    respond_to do |format|
      format.js {}
      format.html {
        redirect_to root_path(:registered => true)
        return
      }
    end
  end

end
