class Web::Pages::ContactsController < Web::ApplicationController
  before_action :build_contact_and_verify_captcha, only: [:create]

  def create
    @contact.save if @contact.errors.empty? && @contact.valid?
    respond_to do |format|
      format.js {}
      format.html {
        redirect_to root_path
        return
      }
    end
  end

  private

  def create_params
    params.require(:message_contact).permit(:from, :sender_name, :body)
  end

  def build_contact_and_verify_captcha
    @contact = ::Message::Contact.new(create_params)
    verify_recaptcha(model: @contact, attribute: :captcha)
  end
end
