class User < ActiveRecord::Base
  extend FriendlyId
  include Model::User::Roles
  include Model::Uid

  attr_accessor :force_registration_validation
  attr_accessor :skip_registration_validation
  attr_accessor :force_generate_access_token
  attr_writer :confirmation_validation

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
  has_many :uploads, dependent: :nullify
  has_many :ingests, through: :uploads, source: :ingest
  has_many :client_accesses, dependent: :destroy, class_name: "Api::ClientAccess"

  acts_as_tagger
  friendly_id :username, use: [:slugged, :history]

  validates :email, presence: true, email_format: true #, uniqueness: true
  validates :email, registration: true, on: :create, if: :should_perform_registration_validation?
  validates :username, presence: true, uniqueness: true, length: { minimum: 2, maximum: 40 }, username_format: true, if: :confirmed_or_confirmation_validation?
  validates :first_name, presence: true, length: { minimum: 1, maximum: 125 }, if: :confirmed_or_confirmation_validation?
  validates :last_name, presence: true, length: { minimum: 1, maximum: 125 }, if: :confirmed_or_confirmation_validation?
  validates :description, length: { maximum: 240 }

  scope :confirmed, lambda { where("users.confirmed_at IS NOT NULL") }

  before_validation :downcase_email, on: :create
  before_save :geocode, if: :has_ip_address?, unless: :geocoded?
  before_save :reverse_geocode, if: :geocoded?

  class << self

    def generate_uid
      SecureRandom.uuid
    end

  end

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

  def name_and_username
    result = ""
    result += name if name.present?
    result += result.blank? ? "@#{username}" : " (@#{username})"
    result.strip!
    result
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

  # E.g. @user.owner_of(@document) -> false
  def owner_of?(record)
    !!(record.respond_to?(:user) && record.user && self == record.user)
  end

  def avatar_url(options = {})
    options.reverse_merge!({size: 96})
    gravatar_id   = Digest::MD5::hexdigest(email).downcase
    gravatar_root = https? ? "https://secure.gravatar.com/" : "http://gravatar.com/"
    "#{gravatar_root}avatar/#{gravatar_id}.png?s=#{options[:size]}&d=identicon"
  end

  def pubsub_channel
    "vz-user-#{self.uid}"
  end

  protected

  def https?
    Rails.env.development? ? false : true
  end

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

  def should_generate_new_friendly_id?
    new_record? || slug.blank? || !!changes[:username]
  end

  private

  def downcase_email
    self.email = email.downcase if email.present?
  end

end
