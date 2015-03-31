class User < ActiveRecord::Base
  include Model::User::Roles

  ACCESS_ID_LENGTH      = 16
  ACCESS_SECRET_LENGTH  = 16

  attr_accessor :force_registration_validation
  attr_accessor :skip_registration_validation
  attr_accessor :force_generate_access_token

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

  has_many :documents, dependent: :nullify
  has_many :ingests, through: :documents
  has_many :uploads, through: :ingests

  acts_as_tagger

  validates :email, presence: true, email_format: true#, uniqueness: true
  validates :email, registration: true, on: :create, if: :should_perform_registration_validation?
  validates :first_name, presence: true, if: :confirmed_or_confirmation_validation?
  validates :last_name, presence: true, if: :confirmed_or_confirmation_validation?

  scope :confirmed, lambda {where("users.confirmed_at IS NOT NULL")}

  before_save :geocode, if: :has_ip_address?, unless: :geocoded?
  before_save :reverse_geocode, if: :geocoded?
  before_save :generate_access_id, :generate_access_secret, if: :generate_access_token?

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

  def name
    [first_name, last_name].reject(&:blank?).join(" ")
  end

  def initials
    self[:initials] || begin
      [first_name.try(:[], 0), last_name.try(:[], 0)].reject(&:blank?).join.upcase
    end
  end

  def css_rgb_color
    digest = Digest::SHA1.hexdigest("#{id.to_i + 1}")
    "rgb(#{digest[0..1].hex}, #{digest[2..3].hex}, #{digest[4..5].hex})"
  end

  def css_hex_color
    self[:css_hex_color] || begin
      digest = Digest::SHA1.hexdigest("#{id.to_i + 1}")
      "##{digest[0..1]}#{digest[2..3]}#{digest[4..5]}"
    end
  end

  def access_token
    if access_id && access_secret
      digest = "#{access_id}:#{access_secret}"
      "#{access_id}:#{Digest::MD5.hexdigest(digest)}"
    end
  end

  def secure_compare_access_secret(hashed_access_secret)
    Devise.secure_compare(Digest::MD5.hexdigest(self.access_id + ':' + self.access_secret), hashed_access_secret)
  end

  protected

  def has_ip_address?
    ip_address.present?
  end

  def ip_address
    current_sign_in_ip || last_sign_in_ip
  end

  def should_perform_registration_validation?
    return false if !!skip_registration_validation
    !Rails.env.test? || @force_registration_validation
  end

  def generate_access_id
    self.access_id = loop do
      random_access_id =  SecureRandom.urlsafe_base64(User::ACCESS_ID_LENGTH, false)
      break random_access_id unless self.class.exists?(access_id: random_access_id)
    end
  end

  def generate_access_secret
    self.access_secret = loop do
      random_access_secret =  SecureRandom.urlsafe_base64(User::ACCESS_SECRET_LENGTH, false)
      break random_access_secret unless self.class.exists?(access_secret: random_access_secret)
    end
  end

  def generate_access_token?
    !access_id || !access_secret || !!force_generate_access_token
  end
end
