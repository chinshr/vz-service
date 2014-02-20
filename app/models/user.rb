class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :trackable, :validatable, 
    :confirmable#, :token_authenticatable

=begin
  def password_required?
    super if confirmed?
  end

  def password_match?
    self.errors[:password] << "can't be blank" if password.blank?
    self.errors[:password_confirmation] << "can't be blank" if password_confirmation.blank?
    self.errors[:password_confirmation] << "does not match password" if password != password_confirmation
    password == password_confirmation && !password.blank?
  end
=end

  def only_if_unconfirmed
    # unless_confirmed {yield}
    pending_any_confirmation {yield}
  end
  
  def has_no_password?
    encrypted_password.blank?
  end
  
  def attempt_set_password(params)
    update_attributes({:password => params[:password], :password_confirmation => params[:password_confirmation]})
  end
  
end
