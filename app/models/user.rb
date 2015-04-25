class User < ActiveRecord::Base
  include Model::User::Roles

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
  has_many :ingests, through: :documents, source: :ingests
  has_many :uploads, through: :ingests
  has_many :client_accesses, dependent: :destroy, class_name: "Api::ClientAccess"

  acts_as_tagger

  validates :email, presence: true, email_format: true#, uniqueness: true
  validates :email, registration: true, on: :create, if: :should_perform_registration_validation?
  validates :first_name, presence: true, if: :confirmed_or_confirmation_validation?
  validates :last_name, presence: true, if: :confirmed_or_confirmation_validation?

  scope :confirmed, lambda {where("users.confirmed_at IS NOT NULL")}

  before_save :geocode, if: :has_ip_address?, unless: :geocoded?
  before_save :reverse_geocode, if: :geocoded?

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

  def active?
    confirmed?
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
end
