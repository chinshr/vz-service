class Ingest < ActiveRecord::Base
  include AASM
  
  CREATED   = 0
  STARTING  = 1
  STARTED   = 2
  STOPPING  = 3
  STOPPED   = 4
  RESETTING = 5
  RESET     = 6
  REMOVING  = 7
  REMOVED   = 8
  FINISHED  = 9
  STATES    = {:created => CREATED, :starting => STARTING, :started => STARTED, :stopping => STOPPING, :stopped => STOPPED,
    :resetting => RESETTING, :reset =>  RESET, :removing => REMOVING, :removed => REMOVED, :finished => FINISHED}
  
  serialize :messages, Hash
  
  belongs_to :upload
  belongs_to :ingestable, polymorphic: true, dependent: :destroy
  
  delegate :s3_url, to: :upload, allow_nil: true
  delegate :s3_key, to: :upload, allow_nil: true
  
  validates :upload, presence: true
  validates :ingestable, presence: true
  
  aasm column: 'aasm_state' do
    state :created, initial: true
    state :starting
    state :started, :enter => :enter_started
    state :stopping
    state :stopped, :enter => :enter_stopped
    state :resetting
    state :reset, :enter => :enter_reset
    state :removing
    state :removed, :enter => :enter_removed
    state :finished, :enter => :enter_finished
    
    event :start do
      transitions :from => [:created, :reset], :to => :starting
    end
    
    event :stop do
      transitions :from => :started, :to => :stopping
    end
    
    event :reset do
      transitions :from => [:started, :stopped], :to => :resetting
    end

    event :remove do
      transitions :from => [:created, :started, :stopped, :reset, :finished], :to => :removing
    end

    event :process do
      transitions :from => :starting, :to => :started
      transitions :from => :stopping, :to => :stopped
      transitions :from => :resetting, :to => :reset
      transitions :from => :removing, :to => :removed
    end
    
    event :finish do
      transitions :from => :started, :to => :finished
    end
    
    event :fail do
      transitions :from => [:created, :starting, :started, :stopping, :stopped, :resetting, :reset], :to => :stopped
    end
  end
  
  def status
    self.class::STATES.symbolize_keys[aasm.current_state]
  end
  
  def log(name, message)
    raise ArgumentError, "name missing" if name.blank?
    name = name.to_s
    if existing_messages = self.messages[name]
      self.messages[name] = [existing_messages, message].flatten
    else
      self.messages[name] = [message]
    end
  end
  
  def log!(name, message)
    log(name, message)
    save!
  end
  
  protected
  
  def enter_started
    self.started_at = Time.now.utc
  end

  def enter_stopped
    self.stopped_at = Time.now.utc
  end

  def enter_reset
    self.reset_at = Time.now.utc
  end

  def enter_finished
    self.finished_at = Time.now.utc
  end
  
  def enter_removed
    self.removed_at = Time.now.utc
  end
end
