class User < ActiveRecord::Base
  extend FriendlyId
  include Model::User::Roles
  include Model::Uid

  serialize :properties, User::Properties

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
  belongs_to :plan

  acts_as_tagger
  friendly_id :username, use: [:slugged, :history]

  validates :email, presence: true, email_format: true, uniqueness: true
  validates :username, presence: true, uniqueness: true, length: { minimum: 2, maximum: 40 }, username_format: true, if: :confirmed_or_confirmation_validation?
  validates :name, presence: true, length: { minimum: 1, maximum: 125 }, if: :confirmed_or_confirmation_validation?
  validates :description, length: { maximum: 240 }

  scope :confirmed, -> { where("users.confirmed_at IS NOT NULL") }
  scope :unconfirmed, -> { where("users.confirmed_at IS NULL") }
  scope :approved, -> { where({approved: true}) }
  scope :unapproved, -> { where({approved: false}) }

  before_validation :downcase_email, on: :create
  before_save :geocode, if: :has_ip_address?, unless: :geocoded?
  before_save :reverse_geocode, if: :geocoded?

  class << self

    def generate_uid
      SecureRandom.uuid
    end

    def update_subscription_plan(subscription)
      if user = subscription.owner
        user.update_column(:plan_id, subscription.plan_id)
      end
    end

    def send_reset_password_instructions(attributes = {})
      recoverable = find_or_initialize_with_errors(reset_password_keys, attributes, :not_found)
      if !recoverable.approved?
        recoverable.errors[:base] << I18n.t("devise.failure.not_approved")
      elsif recoverable.persisted?
        recoverable.send_reset_password_instructions
      end
      recoverable
    end
  end # class methods

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
    if [first_name, last_name].all?(&:blank?)
      self[:name]
    else
      [self[:first_name], self[:last_name]].reject(&:blank?).join(" ")
    end
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

  def properties
    plan_config_hash = (self.plan.try(:config) || {}).as_json
    user_config_hash = (self[:properties].try(:[], :config) || {}).as_json
    merged_config = plan_config_hash.deep_merge(user_config_hash) {|_k, v1, v2| v2.present? ? v2 : v1}
    self[:properties][:config] = merged_config
    self[:properties]
  end

  def active_for_authentication?
    super && approved?
  end

  def inactive_message
    if !approved?
      :not_approved
    else
      super # Use whatever other message
    end
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

  def should_generate_new_friendly_id?
    new_record? || slug.blank? || !!changes[:username]
  end

  private

  def downcase_email
    self.email = email.downcase if email.present?
  end

end
