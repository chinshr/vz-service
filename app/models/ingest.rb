class Ingest < ActiveRecord::Base
  include AASM
  include Model::Filter

  STAGE_START       = 0
  STAGE_HARVEST     = 100
  STAGE_TRANSCODE   = 200
  STAGE_TRANSCRIBE  = 300
  STAGE_INDEX       = 400
  STAGE_ARCHIVE     = 500
  STAGES = {
    start: STAGE_START, harvest: STAGE_HARVEST,
    transcode: STAGE_TRANSCODE, transcribe: STAGE_TRANSCRIBE,
    index: STAGE_INDEX, archive: STAGE_ARCHIVE
  }

  STATE_CREATED     = 0
  STATE_STARTING    = 1
  STATE_STARTED     = 2
  STATE_STOPPING    = 3
  STATE_STOPPED     = 4
  STATE_RESETTING   = 5
  STATE_RESET       = 6
  STATE_REMOVING    = 7
  STATE_REMOVED     = 8
  STATE_FINISHED    = 9
  STATE_RESTARTING  = 10
  STATES = {
    created: STATE_CREATED, starting: STATE_STARTING, started: STATE_STARTED, 
    stopping: STATE_STOPPING, stopped: STATE_STOPPED, resetting: STATE_RESETTING,
    reset: STATE_RESET, removing: STATE_REMOVING, removed: STATE_REMOVED, 
    finished: STATE_FINISHED,  restarting: STATE_RESTARTING
  }

  serialize :messages, Hash

  delegate :s3_key, to: :upload, allow_nil: true

  belongs_to :upload, dependent: :destroy
  belongs_to :document
  has_many :chunks, dependent: :destroy
  accepts_nested_attributes_for :chunks
  has_one :track, through: :document
  accepts_nested_attributes_for :track
  has_many :tracks, through: :chunks, source: :track

  validates :upload, presence: true, on: :create
  validates :document, presence: true

  # public scopes
  filtered_scopes :sort_order, :reverse_sort, :any_of_status, :none_of_status
  scope :sort_order, -> (param) {
    case param.first[0]  # E.g. get first key of {"id"=>"asc"}
    when "id"
      order(self.arel_table[:id].send(param.first[1].to_sym).to_sql)
    when "created_at"
      order(self.arel_table[:created_at].send(param.first[1].to_sym).to_sql)
    else
      raise ArgumentError, "Ignored unrecognized value 'sort_order[]=#{param}'."
    end
  }
  scope :reverse_sort, -> (param) {all.reverse_order if Model::Helper.booleanize(param)}
  scope :any_of_status, -> (params) {where("ingests.aasm_state IN (?)", [params].flatten.map(&:to_s).
    map {|s| s.match(/^([\-]{,1}[0-9]+)$/) ? s : nil}.reject(&:blank?).map {|s| Ingest::STATES.key(s.to_i)}.uniq)}
  scope :none_of_status, -> (params) {where("ingests.aasm_state NOT IN (?)", [params].flatten.map(&:to_s).
    map {|s| s.match(/^([\-]{,1}[0-9]+)$/) ? s : nil}.reject(&:blank?).map {|s| Ingest::STATES.key(s.to_i)}.uniq)}

  aasm column: 'aasm_state' do
    state :created, initial: true
    state :starting, :enter => :enter_starting, :after_enter => :after_enter_starting
    state :started, :enter => :enter_started
    state :stopping, :after_enter => :after_enter_stopping
    state :stopped, :enter => :enter_stopped
    state :resetting, :after_enter => :after_enter_resetting
    state :reset, :enter => :enter_reset
    state :removing, :enter => :enter_removing, :after_enter => :after_enter_removing
    state :removed, :enter => :enter_removed
    state :finished, :enter => :enter_finished
    state :restarting, :after_exit => :after_exit_restarting, :after_enter => :after_enter_restarting

    event :start do
      transitions :from => [:created, :stopped, :reset], :to => :starting, :guard => :has_valid_upload?
    end

    event :stop do
      transitions :from => :started, :to => :stopping
    end

    event :reset do
      transitions :from => [:stopped, :finished], :to => :resetting
    end

    event :remove do
      transitions :from => [:created, :starting, :started, :stopping, :stopped, :resetting, :reset, :removing, :finished], :to => :removing
    end

    event :process do
      transitions :from => [:starting, :restarting, :started], :to => :started
      transitions :from => [:stopping, :stopped], :to => :stopped
      transitions :from => [:resetting, :reset], :to => :reset
      transitions :from => [:removing, :removed], :to => :removed
      transitions :from => :restarting, :to => :started
    end

    event :finish do
      transitions :from => [:started, :finished, :stopped], :to => :finished
    end

    event :fail do
      transitions :from => [:created, :starting, :started, :stopping, :stopped, :resetting, :reset, :removing], :to => :stopped
    end

    event :restart do
      transitions :from => [:starting, :started], :to => :restarting
    end
  end

  class << self
    def policy_class
      IngestPolicy
    end

    def queue_name_from(stage_name)
      "#{stage_name.to_s.upcase}_#{Rails.env.upcase}_QUEUE"
    end
  end

  # e.g. an integer representation of state, like 9 (=finished)
  def status
    self.class::STATES.symbolize_keys[aasm.current_state]
  end

  # Alias for AASM current state E.g. :finished
  def state
    aasm.current_state
  end

  # permissible events
  def events
    aasm.events(aasm.current_state) - [:process, :fail, :finish]
  end

  # force an event
  def event=(value)
    events = Array.wrap(value)
    may_transition?(events) ? call_transition_with(events) : false
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

  # set_progress! 10 => 10%
  def set_progress!(percent)
    with_lock do
      new_progress = percent
      new_progress = new_progress > 100 ? 100 : new_progress
      update_attribute(:progress, new_progress)
    end
  end

  def reload_attribute(attr)
    value = self.class.where(:id=>id).select(attr).first[attr]
    self[attr] = value
  end

  # set_progress! 10 => 10%
  # increment_progress! 1, 5, 80 => 26%
  # increment_progress! 1, 5, 80 => 42%
  # ...
  # increment_progress! 1, 5, 80 => 80%
  # increment_progress! 1, 5, 80 => 80%
  def increment_progress!(counter, denominator, percent_threshold = 100)
    self.class.transaction do
      Rails.env.test? ? reload_attribute(:progress) : lock!
      new_progress = (self[:progress] || 0) + (counter / denominator.to_f * percent_threshold)
      new_progress = new_progress > 100 ? 100 : new_progress
      self.progress = new_progress
      save(:validate => false)
    end
  end

  def progress
    self[:progress].round if self[:progress]
  end

  # TODO: obsolete, refactor
  def document_url
    "http://voyz.es/#{document.slug}"
  end

  # TODO: obsolete, refactor
  def edit_document_url
    "http://voyz.es/#{document.slug}/edit"
  end

  def signal_terminate!
    update_attribute(:terminate, true)
  end

  def clear_terminate!
    update_attribute(:terminate, false)
  end

  def signal_busy!
    update_attribute(:busy, true)
  end

  def clear_busy!
    update_attribute(:busy, false)
  end

  def normalize_chunk_scores!
    self.chunks.group_by(&:position).each do |position, grouped_chunks|
      levenshtein_array = grouped_chunks.each_index.inject([]) do |column, column_index|
        column << grouped_chunks.each_index.inject([]) do |row, row_index|
          row << if grouped_chunks[column_index].text && grouped_chunks[row_index].text
            grouped_chunks[column_index].text.levenshtein_similar(grouped_chunks[row_index].text)
          else
            0.0
          end
        end
      end

      levenshtein_matrix = Matrix.rows(levenshtein_array)
      combined_word_count = grouped_chunks.map(&:text).inject(0) {|r, e| r += e.to_s.split.size}
      eigen_array = grouped_chunks.each_index.inject([]) do |v, index|
        v << (combined_word_count.to_f > 0 ? grouped_chunks[index].text.to_s.split.size / combined_word_count.to_f : 1.0)
      end
      eigen_vector = Vector.elements(eigen_array, true)
      score_vector = levenshtein_matrix * eigen_vector

      # update chunk score
      score_vector.each_with_index do |vector_score, index|
        grouped_chunks[index].score = vector_score
        grouped_chunks[index].save if grouped_chunks[index].changed?
      end
    end
  end

  def score
    chunks.average(:score)
  end

  def duration
    chunks.sum(:duration)
  end

  def update_content_from(grouped_chunks)
    document.with_lock do
      document.update_attributes(html: grouped_chunks.text, rich_text: grouped_chunks.rich_text)
    end
  end

  protected

  def enter_starting
    self.terminate = false
    self.busy      = false
  end

  def after_enter_starting; end

  def after_enter_stopping
    self.terminate = true
  end

  def after_enter_resetting
    self.terminate = true
  end

  def enter_started
    self.started_at = Time.now.utc
  end

  def enter_stopped
    self.stopped_at = Time.now.utc
    self.terminate  = false
    self.busy       = false
  end

  def enter_reset
    self.reset_at  = Time.now.utc
    self.messages  = {}
    self.stage     = nil
    self.progress  = 0
    self.terminate = false
    self.busy      = false
    increment(:iteration)
  end

  def enter_finished
    self.finished_at = Time.now.utc
  end

  def enter_removing
    self.terminate = true
  end

  def enter_removed
    self.terminate  = false
    self.removed_at = Time.now.utc
  end

  def after_exit_restarting
    update_attributes(messages: {}, stage: nil, iteration: iteration + 1)
  end

  def after_enter_restarting
    self.restarted_at = Time.now.utc
    self.terminate    = true
  end

  def after_enter_removing
    ::Ingest::RemoveWorker.perform_async(self.id)
  end

  def has_valid_upload?
    !!(upload && upload.s3_url)
  end

  def may_transition?(events)
    events.present? ? events.any? {|e| send(:"may_#{e}?")} : false
  end

  def call_transition_with(events)
    if event = events.find {|e| send(:"may_#{e}?") ? e : false}
      return send(:"#{event}")
    end
    false
  end
end
