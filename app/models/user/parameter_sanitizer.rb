class User::ParameterSanitizer < Devise::ParameterSanitizer
  private

  def sign_up
    permit self.for(:sign_up) + [:time_zone]
  end
end