class Ingest < ActiveRecord::Base
  include AASM
  
  CREATED    = 0
  STARTING   = 1
  STARTED    = 2
  STOPPING   = 3
  STOPPED    = 4
  RESETTING  = 5
  RESET      = 6
  REMOVING   = 7
  REMOVED    = 8
  FINISHED   = 9
  RESTARTING = 10
  STATES    = {:created => CREATED, :starting => STARTING, :started => STARTED, :stopping => STOPPING, :stopped => STOPPED,
    :resetting => RESETTING, :reset =>  RESET, :removing => REMOVING, :removed => REMOVED, :finished => FINISHED, 
    :restarting => RESTARTING}
  
  serialize :messages, Hash
  
  belongs_to :upload
  belongs_to :ingestable, polymorphic: true, dependent: :destroy
  belongs_to :track
  
  validates :upload, presence: true
  validates :ingestable, presence: true
  
  aasm column: 'aasm_state' do
    state :created, initial: true
    state :starting, :enter => :enter_starting, :after_enter => :after_enter_starting
    state :started, :enter => :enter_started
    state :stopping, :after_enter => :after_enter_stopping
    state :stopped, :enter => :enter_stopped
    state :resetting, :after_enter => :after_enter_resetting
    state :reset, :enter => :enter_reset
    state :removing
    state :removed, :enter => :enter_removed
    state :finished, :enter => :enter_finished
    state :restarting, :after_exit => :after_exit_restarting, :after_enter => :after_enter_restarting
    
    event :start do
      transitions :from => [:created, :stopped, :reset], :to => :starting, :guard => :has_s3_url?
    end
    
    event :stop do
      transitions :from => :started, :to => :stopping
    end
    
    event :reset do
      transitions :from => [:stopped], :to => :resetting
    end

    event :remove do
      transitions :from => [:created, :started, :stopped, :reset, :finished], :to => :removing
    end

    event :process do
      transitions :from => [:starting, :started], :to => :started
      transitions :from => [:stopping, :stopped], :to => :stopped
      transitions :from => [:resetting, :reset], :to => :reset
      transitions :from => [:removing, :removed], :to => :removed
      transitions :from => :restarting, :to => :starting
    end
    
    event :finish do
      transitions :from => [:started, :finished, :stopped], :to => :finished
    end
    
    event :fail do
      transitions :from => [:created, :starting, :started, :stopping, :stopped, :resetting, :reset], :to => :stopped
    end
    
    event :restart do
      transitions :from => [:starting, :started], :to => :restarting
    end
  end
  
  def status
    self.class::STATES.symbolize_keys[aasm.current_state]
  end
  
  def state
    aasm.current_state
  end
  
  def continue_processing?
    !stage.blank? && starting?
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
  
  def s3_url
    self[:s3_url] || begin
      upload ? upload.s3_url : nil
    end
  end
  
  def has_s3_url?
    !s3_url.blank?
  end
  
  def s3_key
    s3_url ? s3_url.split("/").last : nil
  end
  
  # set_progress! 10 => 10%
  def set_progress!(percent)
    Ingest.transaction do
      lock!
      new_progress = percent
      new_progress = new_progress > 100 ? 100 : new_progress
      update_attribute(:progress, new_progress)
    end
  end

  # set_progress! 10 => 10%
  # increment_progress! 1, 5, 0.8 => 26%
  # increment_progress! 1, 5, 0.8 => 42%
  # ...
  # increment_progress! 1, 5, 0.8 => 90%
  def increment_progress!(counter, denominator, factor = 1.0)
    Ingest.transaction do
      lock!
      new_progress = (self[:progress] || 0) + (counter / denominator.to_f * factor * 100)
      new_progress = new_progress > 100 ? 100 : new_progress
      update_attribute(:progress, new_progress)
    end
  end
  
  def progress
    self[:progress].round if self[:progress]
  end
  
  def ingestable_url
    "http://voyz.es/#{ingestable.slug}"
  end

  def edit_ingestable_url
    "http://voyz.es/#{ingestable.slug}/edit"
  end
  
  protected

  def enter_starting; end
  def after_enter_starting; end
  
  def after_enter_stopping; end
  def after_enter_resetting; end
  
  def enter_started
    self.started_at = Time.now.utc
  end

  def enter_stopped
    self.stopped_at = Time.now.utc
  end
  
  def enter_reset
    self.reset_at = Time.now.utc
    self.messages = {}
    self.increment(:iteration)
    self.stage = nil
  end

  def enter_finished
    self.finished_at = Time.now.utc
  end
  
  def enter_removed
    self.removed_at = Time.now.utc
  end
  
  def after_exit_restarting
    update_attributes(messages: {}, stage: nil, iteration: iteration + 1)
  end
  
  def after_enter_restarting
    self.restarted_at = Time.now.utc
  end
end
