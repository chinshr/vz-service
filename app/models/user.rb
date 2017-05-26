class User < ActiveRecord::Base
  extend FriendlyId
  include Model::User::Roles
  include Model::Uid

  SIGNUP_ATTRIBUTES = [:email, :name, :username]

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
  acts_as_paranoid

  validates :email, presence: true, email_format: true, uniqueness: true
  validates :first_name, presence: true, length: { minimum: 2, maximum: 125 },
    name_format: true, if: :should_validate_first_name?
  validates :last_name, presence: true, length: { minimum: 2, maximum: 125 },
    name_format: true, if: :should_validate_last_name?
  validates :name, presence: true, length: { minimum: 2, maximum: 250 },
    name_format: true, if: :should_validate_name?
  validates :username, presence: true, uniqueness: true, length: { minimum: 2, maximum: 40 },
    username_format: true, if: :should_validate_username?
  validates :description, length: { maximum: 240 }, if: :should_validate_description?

  scope :confirmed, -> { where("users.confirmed_at IS NOT NULL") }
  scope :unconfirmed, -> { where("users.confirmed_at IS NULL") }
  scope :approved, -> { where({approved: true}) }
  scope :unapproved, -> { where({approved: false}) }

  before_validation :downcase_email, on: :create
  before_save :geocode, if: :has_ip_address?, unless: :geocoded?
  before_save :reverse_geocode, if: :geocoded?
  after_commit :send_on_create_admin_notification, on: :create, if: :send_admin_notification?

  class << self

    def generate_uid
      SecureRandom.uuid
    end

    def update_subscription_plan(subscription, options = {})
      if user = subscription.owner
        if options.try(:[], :cancel)
          user.plan_id           = nil
          user.properties.config = Plan::Config.new
          user.save(validate: false)
        elsif subscription.plan_id
          user.plan_id           = subscription.plan_id
          user.properties.config = subscription.plan.config
          user.save(validate: false)
        end
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

  def upstream_validation=(value)
    @upstream_validation = !!value
  end

  def upstream_validation?
    !!@upstream_validation
  end

  def name
    joined_list = [self[:first_name], self[:last_name]].reject(&:blank?)
    joined_list.empty? ? self[:name] : joined_list.join(" ")
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
      result = ""
      if first_name.present? || last_name.present?
        result = [first_name.try(:[], 0), last_name.try(:[], 0)].reject(&:blank?).join.upcase
      elsif self.name.present?
        result = name.split.map {|n| n.try(:[], 0)}.reject(&:blank?).join.upcase
      end
      result
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

  def skip_admin_notification!
    @skip_admin_notification = true
  end

  def send_on_create_admin_notification
    if approved?
      User::AdminMailer.new_user_signup(self).deliver_later
    else
      User::AdminMailer.new_user_waiting_for_approval(self).deliver_later
    end
  end
  alias_method :send_admin_notification, :send_on_create_admin_notification

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

  def send_admin_notification?
    !@skip_admin_notification
  end

  private

  def downcase_email
    self.email = email.downcase if email.present?
  end

  def should_validate_first_name?
    SIGNUP_ATTRIBUTES.include?(:first_name) && (upstream_validation? || confirmation_validation? || confirmed?)
  end

  def should_validate_last_name?
    SIGNUP_ATTRIBUTES.include?(:last_name) && (upstream_validation? || confirmation_validation? || confirmed?)
  end

  def should_validate_name?
    SIGNUP_ATTRIBUTES.include?(:name) && (upstream_validation? || confirmation_validation? || confirmed?)
  end

  def should_validate_username?
    SIGNUP_ATTRIBUTES.include?(:username) && (upstream_validation? || confirmation_validation? || confirmed?)
  end

  def should_validate_description?
    confirmation_validation? || confirmed?
  end
end
