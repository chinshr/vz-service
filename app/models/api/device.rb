class Api::Device < ActiveRecord::Base
  self.table_name = "api_devices"
  include Model::Filter

  belongs_to :client, class_name: "Api::Client"
  belongs_to :client_access, class_name: "Api::ClientAccess"

  delegate :user, to: :client_access, allow_nil: true
  delegate :platform, to: :client, allow_nil: true

  attr_accessor :authorized

  validates :uid, presence: true, uniqueness: true

  filtered_scopes :authorized, :uid, :device_name,
    :any_of_platform_ids, :any_of_user_ids
  scope :authorized, -> (param) {
    joins(:client_access).
    where("api_client_accesses.aasm_state = ? ", "#{(["true", "1"].include?(param.to_s.downcase) ? 'active' : 'inactive')}")
  }
  scope :uid, -> (params) { where(:uid => params) }
  scope :device_name, -> (param) { where(device_name: param) }
  scope :any_of_platform_ids, -> (params) {
    joins(:client)
      .where (["api_clients.platform_id IN (?)", params])
  }
  scope :any_of_user_ids, -> (params) {
    joins(:client_access)
      .where(["api_client_accesses.user_id IN (?)", params])
  }

  before_save :generate_human_name, :if => Proc.new {|model| model.device_name.blank?}

  def authorize!
    max_number_of_device_auths_per_account = ENV['MAX_NUMBER_OF_DEVICES_PER_ACCOUNT'].to_i
    max_number_of_devices_per_period       = ENV['MAX_NUMBER_OF_TOTAL_AUTHORIZED_DEVICES_PER_PERIOD'].to_i
    device_authorization_time_period       = ENV['DEVICE_AUTHORIZATIONS_PERIOD_IN_DAYS'].to_i

    client_access.activate! if authorized?

    if client && client.platform && client.platform.cap && client_access.user && client_access.user.user? && max_number_of_device_auths_per_account > 0 && max_number_of_devices_per_period > 0
      number_of_authorized_devices_for_account = client_access.user.client_accesses.joins(:clients => :platform).where("api_client_accesses.aasm_state = ? AND api_platforms.cap = ?", 'active', true).count
      if device_authorization_time_period > 0
        number_of_authorized_devices_within_time_period = client_access.user.client_accesses.joins(:clients => :platform).where("api_client_accesses.aasm_state = ? AND api_client_accesses.created_at > ? AND api_platforms.cap = ?", 'active', device_authorization_time_period.days.ago, true).count
      else
        number_of_authorized_devices_within_time_period = client_access.user.client_accesses.joins(:clients => :platform).where("api_client_accesses.aasm_state = ? AND api_client_accesses.created_at > ? AND api_platforms.cap = ?", 'active', 1.month.ago, true).count
      end
      if number_of_authorized_devices_for_account >= max_number_of_device_auths_per_account
        raise Api::Exception::DeviceLimit.new(I18n.t('api.error_code.authorization_error.max_number_of_device_authorizations_allowed'))
      elsif number_of_authorized_devices_within_time_period >= max_number_of_devices_per_period
        raise Api::Exception::DeviceLimitPeriod.new(I18n.t('api.error_code.authorization_error.max_number_of_device_authorizations_allowed_per_period', days: device_authorization_time_period))
      end
    elsif client && client.platform && client.platform.cap && client_access.user && client_access.user.user? && max_number_of_device_auths_per_account > 0
      number_of_authorized_devices_for_account = client_access.user.client_accesses.joins(:clients => :platform).where("api_client_accesses.aasm_state = ? AND api_platforms.cap = ?", 'active', true).count
      if number_of_authorized_devices_for_account >= max_number_of_device_auths_per_account
        raise Api::Exception::DeviceLimit.new(I18n.t('api.error_code.authorization_error.max_number_of_device_authorizations_allowed'))
      end
    end
    client_access.activate and client_access.save!
  end

  def deauthorize!
    self.client_access.deactivate and self.client_access.save!
  end

  def authorized?
    client_access ? self.client_access.active? : false
  end
  alias_method :authorized, :authorized?

  private

  def generate_human_name
    self.device_name = if self.platform.present?
      platform_count = self.class.any_of_platform_ids(self.platform.id).count.to_i
      humanize_platform_name = self.platform.name.split(":").first.underscore.humanize
      "#{humanize_platform_name} #{platform_count + 1}".parameterize
    else
      # For certain clients like CPW and admin, the concept of devices is not really applicable since we don't indicate
      # what platform they are to restrict playback or catalog. We'll just prepend 'Client' with client name as the default. 
      "Client #{self.client.name}".parameterize
    end
  end
end
