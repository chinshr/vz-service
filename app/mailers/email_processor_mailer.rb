class EmailProcessorMailer < ActionMailer::Base
  default from: "my@voyz.es"
  default reply_to: "my@voyz.es"

  def invalid_message(message)
    @message = message
    mail(to: message.sender.email, subject: "Sorry, your message cannot be processed.")
  end

  def valid_message(message)
    @message = message
    mail(to: message.sender.email, subject: "We are working hard processing your message.")
  end

end
