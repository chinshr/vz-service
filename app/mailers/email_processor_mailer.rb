class EmailProcessorMailer < ApplicationMailer
  default from: "no-reply@voyz.es"
  # default reply_to: "my@voyz.es"

  def invalid_message(message)
    @message = message
    mail(to: message.sender.email,
      subject: "Sorry, your message cannot be processed.",
      bcc: APP_CONFIG['ADMIN_EMAIL_ADDRESSES'])
  end

  def valid_message(message)
    @message = message
    mail(to: message.sender.email,
      subject: "We are working hard processing your message",
      bcc: APP_CONFIG['ADMIN_EMAIL_ADDRESSES']
    )
  end

end
