class EmailProcessorMailer < ActionMailer::Base
  default from: "my@voyz.es"
  default reply_to: "my@voyz.es"

  def invalid_message(message)
    @message = message
    mail(to: message.sender.email, subject: "Sorry, your message cannot be transcribed.")
  end

  def valid_message(message)
    @message = message
    mail(to: message.sender.email, subject: "We are working hard transcribing your message.")
  end

end
