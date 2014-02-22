class EndpointMailer < ActionMailer::Base
  default from: "i@voyz.es"
  default reply_to: "i@voyz.es"
  
  def invalid_attachment(upload)
    mail(to: upload.user.email, subject: "One of your attachments could not be processed.")
  end
  
end
