class Message::ContactMailer < ApplicationMailer
  default from: "support@voyz.es",
    reply_to: "support@voyz.es"

  def confirmation(contact)
    @contact = contact
    mail(to: @contact.from,
      subject: "Thanks for contacting VOYZ.ES.",
      bcc: APP_CONFIG['ADMIN_EMAIL_ADDRESSES'])
  end

end
