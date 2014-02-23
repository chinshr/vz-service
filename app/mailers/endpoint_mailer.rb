class EndpointMailer < ActionMailer::Base
  default from: "i@voyz.es"
  default reply_to: "i@voyz.es"
  
  def invalid_message(message)
    mail(to: message.sender.email, subject: "Sorry, your message could not be processed.")
  end

  def valid_message(message)
    mail(to: message.sender.email, subject: "Congrats, we are processing your audio files.")
  end
  
end
