class Api::Platform < ActiveRecord::Base
  self.table_name = "api_platforms"
  include Model::Filter
  include Model::Uid
  include AASM

  self.uid_length = 8
  STATUS_INACTIVE = 0
  STATUS_ACTIVE   = 1
  STATES          = {:active => STATUS_ACTIVE, :inactive => STATUS_INACTIVE}

  has_many :clients

  validates :name, presence: true, uniqueness: {scope: :version}
  validates :version, presence: true
  validates :uid, presence: true, length: {is: 8}

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

  protected

  def after_enter_inactive
    self.deactivated_at = Time.zone.now
  end

  def after_enter_active
    self.activated_at = Time.zone.now
  end
end
