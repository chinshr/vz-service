class RegistrationMailer < ActionMailer::Base
  default from: "no-reply@voyz.es"

  def confirmation(registration)
    @registration = registration
    mail(to: @registration.email, subject: "Thanks for your interest in VOYZ.ES.",
      bcc: APP_CONFIG['ADMIN_EMAIL_ADDRESSES'])
  end

  def accepted(registration)
    @registration = registration
    mail(to: @registration.email, subject: "Congrats, you were accepted to the beta program.",
      bcc: APP_CONFIG['ADMIN_EMAIL_ADDRESSES'])
  end

end
