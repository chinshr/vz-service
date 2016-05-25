class Ingest < ActiveRecord::Base
  include AASM
  include Model::AASM::Support
  include Model::Filter
  include Model::Uid
  include Model::S3
  include Wisper::Publisher

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

  delegate :track, to: :document, allow_nil: true  # document's master track
  delegate :track=, to: :document, allow_nil: true # dito

  belongs_to :upload, dependent: :destroy
  belongs_to :document
  has_many :segments, foreign_key: :ingest_id, dependent: :nullify
  has_many :chunks, through: :segments, source: :chunk, dependent: :destroy do
    def create(chunk_attributes)
      Chunk.create({ingest: proxy_association.owner, document: proxy_association.owner.document}.merge(chunk_attributes))
    end
  end
  has_many :tracks, -> { uniq }, through: :chunks, source: :track
  has_many :tracks_including_master_track, -> {uniq}, through: :segments, source: :track, class_name: "Track"
  has_many :workers, :class_name => "Ingest::Worker", :dependent => :destroy
  has_many :servers, through: :workers
  has_many :images, :class_name => "::Image", :foreign_key => :ingest_id, :dependent => :destroy

  acts_as_paranoid

  validates :type, presence: true

  # public scopes
  filtered_scopes :sort_order, :reverse_sort, :any_of_status, :none_of_status,
    :document_id, :is_busy, :is_terminate
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
  scope :any_of_status, -> (params) { where("ingests.aasm_state IN (?)", [params].flatten.map(&:to_s).
    map {|s| s.match(/^([\-]{,1}[0-9]+)$/) ? s : nil}.reject(&:blank?).map {|s| Ingest::STATES.key(s.to_i)}.uniq) }
  scope :none_of_status, -> (params) {where("ingests.aasm_state NOT IN (?)", [params].flatten.map(&:to_s).
    map {|s| s.match(/^([\-]{,1}[0-9]+)$/) ? s : nil}.reject(&:blank?).map {|s| Ingest::STATES.key(s.to_i)}.uniq)}
  scope :document_id, -> (params) { where(document_id: params) }
  scope :is_busy, -> (param) { where("ingests.busy = ?", Model::Helper.booleanize(param)) }
  scope :is_terminate, -> (param) { where("ingests.terminate = ?", Model::Helper.booleanize(param)) }

  aasm column: 'aasm_state' do
    state :created, initial: true
    state :starting, :enter => :enter_starting, :after_enter => :after_enter_starting
    state :started, :enter => :enter_started
    state :stopping, :enter => :enter_stopping, :after_enter => :after_enter_stopping
    state :stopped, :enter => :enter_stopped, :after_enter => :after_enter_stopped
    state :resetting, :enter => :enter_resetting, :after_enter => :after_enter_resetting
    state :reset, :enter => :enter_reset, :after_enter => :after_enter_reset
    state :removing, :enter => :enter_removing, :after_enter => :after_enter_removing
    state :removed, :enter => :enter_removed, :after_enter => :after_enter_removed
    state :finished, :enter => :enter_finished, :after_enter => :after_enter_finished
    state :restarting, :after_exit => :after_exit_restarting, :after_enter => :after_enter_restarting

    event :start, :after_commit => :after_commit_event_start do
      transitions :from => [:created, :stopped, :reset], :to => :starting, :guard => :has_valid_source_url?
    end

    event :stop, :after => :after_event_stop do
      transitions :from => [:starting, :restarting, :started], :to => :stopping
    end

    event :reset, :after => :after_event_reset do
      transitions :from => [:stopped, :finished], :to => :resetting
    end

    event :remove, :after => :after_event_remove do
      transitions :from => [:created, :starting, :restarting, :started, :stopping, :stopped, :resetting, :reset, :removing, :finished], :to => :removing
    end

    event :process, :after_commit => :after_commit_event_process do
      transitions :from => [:starting, :restarting, :started], :to => :started
      transitions :from => [:stopping, :stopped], :to => :stopped, :guard => :not_busy?
      transitions :from => [:resetting, :reset], :to => :reset, :guard => :not_busy?
      transitions :from => [:removing, :removed], :to => :removed, :guard => :not_busy?
      transitions :from => :restarting, :to => :started
    end

    event :finish, :after_commit => :after_commit_event_finish do
      transitions :from => [:started, :finished, :stopped], :to => :finished
    end

    event :fail, :after_commit => :after_commit_event_fail do
      transitions :from => [:created, :starting, :started, :restarting, :stopping, :stopped, :resetting, :reset, :removing], :to => :stopped
    end

    event :restart, :after_commit => :after_commit_event_restart do
      transitions :from => [:starting, :started], :to => :restarting
    end
  end

  before_validation :set_handle, on: :create
  after_commit :after_commit_event_stop,
    :after_commit_event_reset,
    :after_commit_event_remove,
    :refresh_upload
  after_destroy :perform_delete_job

  class << self

    # Type casts to the class specified in :type parameter
    #
    # E.g.
    #
    #   Ingest.new(:type => :audio, ...) -> Ingest::AudioIngest
    #   Ingest.new(:type => "audio_ingest", ...) -> Ingest::AudioIngest
    #   Ingest.create(:type => "Ingest::AudioIngest", ...) -> Ingest::AudioIngest
    #
    def new_with_cast(*a, &b)
      if (h = a.first).is_a? Hash and (type = h[:type] || h['type']) and
        (k = type.class == Class ? type : promote_upload_class_for(type, h)) != self
        raise NameError, "unknown type for Ingest" if !k || !(k < self)
        instance = k.new(*a, &b)
        return instance
      end
      new_without_cast(*a, &b)
    end
    alias_method_chain :new, :cast

    # TODO: obsolete
    def policy_class
      IngestPolicy
    end

    def generate_uid
      SecureRandom.uuid
    end

    private

    # E.g. "audio" => Ingest::AudioIngest
    def class_for(type)
      class_name = class_name_for(type)
      class_name.constantize if class_name
    end

    # E.g.
    #
    #    "audio_ingest" -> "Ingest::AudioIngest" or
    #    "audio"        -> "Ingest::AudioIngest"
    #
    def class_name_for(name)
      class_name = if name.to_s.index("::")
        "#{name}"
      else
        name.to_s.index("ingest") ? "Ingest::#{(name.to_s.classify)}" : "Ingest::#{(name.to_s.classify)}Ingest"
      end
      class_name.constantize.name
    rescue NameError
      nil
    end

    def promote_upload_class_for(name, attributes = {})
      attributes.symbolize_keys! if attributes.respond_to?(:symbolize_keys!)
      klass = class_for(name)
      raise NameError, "unknown Ingest subclass '#{name}'" unless klass
      attributes[:type] = klass.name
      klass
    end

  end  # ClassMethods

  def stages
    []
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

  def purge_log!
    update_attribute(:messages, {})
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

  # NOT inverse
  def not_busy?; !busy?; end
  def not_terminate?; !terminate?; end
  def not_created?; !created?; end
  def not_starting?; !starting?; end
  def not_started?; !started?; end
  def not_stopping?; !stopping?; end
  def not_stopped?; !stopped?; end
  def not_resetting?; !resetting?; end
  def not_reset?; !reset?; end
  def not_removing?; !removing?; end
  def not_finished?; !finished?; end
  def not_restarting?; !restarting?; end

  def progress
    self[:progress].to_f
  end

  def progress=(value)
    self[:progress] = value.round(2) if value
  end

  # TODO: obsolete, refactor
  def document_url
    "http://voyz.es/#{document.slug}"
  end

  # TODO: obsolete, refactor
  def edit_document_url
    "http://voyz.es/#{document.slug}/edit"
  end

  def clear_terminate!
    update_attribute(:terminate, false)
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

  def update_content_from(grouped_chunks)
    document.with_lock do
      document.update_attributes(html: grouped_chunks.text, rich_text: grouped_chunks.rich_text)
    end
  end

  def perform_delete_job
    Ingest::DeleteJob.perform_later(self.id)
  end

  protected

  #--- enter

  def enter_starting
    self.terminate = false
    self.busy      = false
  end

  def enter_stopping
    self.terminate = true
  end

  def enter_started
    self.started_at = Time.zone.now
  end

  def enter_stopped
    self.stopped_at = Time.zone.now
    self.terminate  = false
    self.busy       = false
  end

  def enter_reset
    self.reset_at  = Time.zone.now
    self.messages  = {}
    self.progress  = 0
    self.terminate = false
    self.busy      = false
  end

  def enter_finished
    self.finished_at = Time.zone.now
    self.progress    = 100
  end

  def enter_removing
    self.terminate = true
  end

  def enter_removed
    self.terminate  = false
    self.removed_at = Time.zone.now
  end

  def enter_resetting
    self.terminate = true
  end

  #--- after_enter

  def after_enter_starting; end
  def after_enter_stopping; end
  def after_enter_stopped; end
  def after_enter_resetting; end

  def after_enter_reset
    increment! :iteration
  end

  def after_enter_finished; end

  def after_enter_removed; end

  def after_enter_restarting
    self.restarted_at = Time.zone.now
    self.terminate    = true
  end

  def after_exit_restarting
    reset_stage!
    increment! :iteration
    purge_log!
  end

  def after_enter_removing; end

  #--- after_commit_event

  def after_commit_event_start; end

  def after_event_stop
    # Note: Unexpected AASM behavior makes us
    # do this hack:
    # https://github.com/aasm/aasm/issues/313
    @after_commit_event_stop = true
  end

  def after_commit_event_stop
    Ingest::StopJob.perform_later(self.id) if @after_commit_event_stop
    @after_commit_event_stop = false
  end

  def after_event_reset
    # Note: dito.
    @after_commit_event_reset = true
  end

  def after_commit_event_reset
    Ingest::ResetJob.perform_later(self.id) if @after_commit_event_reset
    @after_commit_event_reset = false
  end

  def after_event_remove
    # Note: dito.
    @after_commit_event_remove = true
  end

  def after_commit_event_remove
    Ingest::RemoveJob.perform_later(self.id) if @after_commit_event_remove
    @after_commit_event_remove = false
  end

  def after_commit_event_process; end
  def after_commit_event_finish; end

  def after_commit_event_fail
    update_attributes(terminate: true)
  end

  def after_commit_event_restart; end

  def set_handle
    self[:handle] ||= begin
      if has_s3_source_url?
        # derive handle from original s3 url
        source_url.split("/").last
      else
        # otherwise, generate a random handle
        chars = [('a'..'z'), ('0'..'9')].map {|i| i.to_a}.flatten
        String.new.tap {|s| 1.upto(20) {|i| s << chars[rand(chars.size - 1)]}}
      end
    end
  end

  private

  def has_valid_source_url?
    Model::URI::Target.new(source_url).valid?
  end

  def refresh_upload
    if transaction_include_any_action?([:create]) ||
      previous_changes[:progress] ||
      previous_changes[:aasm_state] ||
      previous_changes[:aasm_stage]

      publish(:refresh_upload, upload) if upload
    end
  end

  def has_upload?
    upload.present?
  end
end
