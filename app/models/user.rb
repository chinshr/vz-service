class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :trackable, :validatable, 
    :confirmable

  geocoded_by :ip_address, :latitude  => :lat, :longitude => :lng
  reverse_geocoded_by :lat, :lng do |record, results|
    if geo = results.first
      record.city         = geo.city
      record.address      = geo.address
      record.postal_code  = geo.postal_code
      record.region_name  = geo.state
      record.region_code  = geo.state_code
      record.country_code = geo.country_code
    end
  end
  
  has_many :uploads
  
  validates :first_name, presence: true, :if => :confirmed_or_confirmation_validation?
  validates :last_name, presence: true, :if => :confirmed_or_confirmation_validation?
  
  scope :confirmed, lambda {where("users.confirmed_at IS NOT NULL")}
  
  before_save :geocode, :if => :has_ip_address?, :unless => :geocoded?
  before_save :reverse_geocode, :if => :geocoded?

  def password_required?
    # previous = !persisted? || !password.nil? || !password_confirmation.nil?
    super if confirmed?
    confirmation_validation?
  end

  def only_if_unconfirmed
    # unless_confirmed {yield}
    pending_any_confirmation {yield}
  end
  
  def has_no_password?
    encrypted_password.blank?
  end
  
  def confirm_set_with(params)
    @confirmation_validation = true
    update_attributes(params)
  end

  def confirmation_validation?
    !!@confirmation_validation
  end
  
  def confirmed_or_confirmation_validation?
    confirmed? || confirmation_validation?
  end

  protected

  def has_ip_address?
    ip_address.present?
  end
  
  def ip_address
    current_sign_in_ip || last_sign_in_ip
  end
end
