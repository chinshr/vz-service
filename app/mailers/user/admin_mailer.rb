class User::AdminMailer < ApplicationMailer
  default from: "no-reply@voyz.es"

  def new_user_signup(user)
    @user = user
    mail(to: APP_CONFIG['ADMIN_EMAIL_ADDRESSES'],
      subject: "New user signup")
  end

  def new_user_waiting_for_approval(user)
    @user = user
    mail(to: APP_CONFIG['ADMIN_EMAIL_ADDRESSES'],
      subject: "New user waiting for approval")
  end

end
