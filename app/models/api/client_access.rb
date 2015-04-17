class Api::ClientAccess < ActiveRecord::Base
  self.table_name = "api_client_accesses"
  include Model::Uid
  include AASM

  self.uid_length       = 40
  ACCESS_SECRET_LENGTH  = 32
  ACCESS_STATUS_FAILED  = -1
  ACCESS_STATUS_CLIENT  = 0
  ACCESS_STATUS_ACCOUNT = 1
  STATUS_INACTIVE       = 0
  STATUS_ACTIVE         = 1
  STATES = {:active => STATUS_ACTIVE, :inactive => STATUS_INACTIVE}

  belongs_to :client, class_name: "Api::Client"
  belongs_to :user
  has_many :devices
  has_many :clients, :through => :devices do
    def create(client_attributes)
      client_access = self.proxy_association.owner
      client = Api::Client.create(client_attributes)
      if device = Api::Device.find_by(uid: client_access.device_uid)
        device.client_access = client_access and device.save!
      else
        Api::Device.where(uid: client_access.device_uid).scoping do
          self.concat(client)
        end
      end
      return client
    end
  end

  default_scope { where("api_client_accesses.deleted_at IS NULL") }
  scope :without_deleted, -> { unscoped.where("api_client_accesses.deleted_at IS NULL") }
  scope :with_deleted, -> { unscoped }

  before_create :generate_secret

  aasm :column => 'aasm_state' do
    state :inactive, initial: true, after_enter: :after_enter_inactive
    state :active, after_enter: :after_enter_active

    event :activate do
      transitions :from => :inactive, :to => :active
    end

    event :deactivate do
      transitions :from => :active, :to => :inactive
    end
  end

  def client
    @client ||= begin
      self.clients.try(:first) || Api::Client.find_by(id: self.client_id)
    end
  end

  def platform
    self.try(:client).try(:platform)
  end

  def generate_secret
    self.access_secret = SecureRandom.urlsafe_base64(self.class::ACCESS_SECRET_LENGTH, false)
  end

  def sign_in(user)
    if user
      self.user = user
      # note that the authorization sets the status to be ClientAccess::STATUS_ACCOUNT
      if !devices.empty?
        begin
          devices.first.authorize! # unless current_access.devices.first.authorized?
        rescue AASM::InvalidTransition
          # Ignore the invalid state transition error.
          # raise Api::Exception::InvalidStateTransition.new
        end
      else
        # otherwise, if there are no devices we need to set this manually and save
        self.access_status = Api::ClientAccess::ACCESS_STATUS_ACCOUNT
      end
      save!
    end
  end

  def kill_clones
    if self.device_user_uid
      if user_id.nil?
        ActiveRecord::Base.connection.execute("UPDATE api_client_accesses SET deleted_at = now() WHERE user_id IS NULL AND device_uid = #{ActiveRecord::Base.sanitize(self.device_uid)}
        AND id <> #{ActiveRecord::Base.sanitize(self.id)} AND device_user_uid = #{ActiveRecord::Base.sanitize(self.device_user_uid)}")
      else
        ActiveRecord::Base.connection.execute("UPDATE api_client_accesses SET deleted_at = now() WHERE user_id = #{ActiveRecord::Base.sanitize(self.user_id)}
        AND device_uid = #{ActiveRecord::Base.sanitize(self.device_uid)}
        AND id <> #{ActiveRecord::Base.sanitize(self.id)} AND device_user_uid = #{ActiveRecord::Base.sanitize(self.device_user_uid)}")
      end
    elsif self.clients.first
      if user_id.nil?
        ActiveRecord::Base.connection.execute("UPDATE api_client_accesses SET deleted_at = now() WHERE user_id IS NULL AND device_uid = #{ActiveRecord::Base.sanitize(self.device_uid)}
        AND id <> #{ActiveRecord::Base.sanitize(self.id)}")
      else
        ActiveRecord::Base.connection.execute("UPDATE api_client_accesses SET deleted_at = now() WHERE user_id = #{ActiveRecord::Base.sanitize(self.user_id)}
        AND device_uid= #{ActiveRecord::Base.sanitize(self.device_uid)}
        AND id <> #{ActiveRecord::Base.sanitize(self.id)}")
      end
    else
      if user_id.nil?
        ActiveRecord::Base.connection.execute("UPDATE api_client_accesses SET deleted_at = now() WHERE user_id IS NULL AND device_uid = #{ActiveRecord::Base.sanitize(self.device_uid)}
        AND id <> #{ActiveRecord::Base.sanitize(self.id)}")
      else
        ActiveRecord::Base.connection.execute("UPDATE api_client_accesses SET deleted_at = now() WHERE user_id = #{ActiveRecord::Base.sanitize(self.user_id)}
        AND device_uid= #{ActiveRecord::Base.sanitize(self.device_uid)}
        AND id <> #{ActiveRecord::Base.sanitize(self.id)}")
      end
    end
  end

  protected

  def after_enter_inactive
    self.deactivated_at = Time.zone.now
  end

  def after_enter_active
    self.activated_at = Time.zone.now
  end
end
