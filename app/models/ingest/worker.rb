class ::Ingest::Worker < ActiveRecord::Base
  include AASM
  include Model::AASM::Support
  include Model::Filter
  include Model::Uid

  self.table_name = "ingest_workers"

  delegate :progress, to: :ingest, allow_nil: true
  delegate :progress=, to: :ingest, allow_nil: true

  STATE_CREATED  = 0
  STATE_RUNNING  = 1
  STATE_FINISHED = 2
  STATE_STOPPED  = 3
  STATES = {
    created: STATE_CREATED, running: STATE_RUNNING, finished: STATE_FINISHED, stopped: STATE_STOPPED
  }

  belongs_to :ingest
  belongs_to :server

  validates :worker_name, presence: true
  validates :ingest, presence: true

  filtered_scopes :sort_order, :reverse_sort, :any_of_status, :none_of_status,
    :any_of_state, :none_of_state, :ingest_id
  scope :sort_order, -> (param) {
    case param.first[0]  # E.g. get first key of {"id"=>"asc"}
    when "id"
      order(self.arel_table[:id].send(param.first[1].to_sym).to_sql)
    when "created_at"
      order(self.arel_table[:created_at].send(param.first[1].to_sym).to_sql)
    when "started_at"
      order(self.arel_table[:started_at].send(param.first[1].to_sym).to_sql)
    when "stopped_at"
      order(self.arel_table[:stopped_at].send(param.first[1].to_sym).to_sql)
    else
      raise ArgumentError, "Ignored unrecognized value 'sort_order[]=#{param}'."
    end
  }
  scope :reverse_sort, -> (param) {all.reverse_order if Model::Helper.booleanize(param)}
  scope :any_of_status, -> (params) { where("ingest_workers.aasm_state IN (?)", [params].flatten.map(&:to_s).
    map {|s| s.match(/^([\-]{,1}[0-9]+)$/) ? s : nil}.reject(&:blank?).map {|s| Ingest::Worker::STATES.key(s.to_i)}.uniq) }
  scope :none_of_status, -> (params) {where("ingest_workers.aasm_state NOT IN (?)", [params].flatten.map(&:to_s).
    map {|s| s.match(/^([\-]{,1}[0-9]+)$/) ? s : nil}.reject(&:blank?).map {|s| Ingest::Worker::STATES.key(s.to_i)}.uniq)}
  scope :any_of_state, -> (params) { where("ingest_workers.aasm_state IN (?)", [params].flatten.map(&:to_s).map(&:downcase)) }
  scope :none_of_state, -> (params) { where("ingest_workers.aasm_state NOT IN (?)", [params].flatten.map(&:to_s).map(&:downcase)) }
  scope :ingest_id, -> (params) { where(ingest_id: params) }

  scope :eager_load_associations, -> { eager_load([:ingest, :server]) }
  scope :active, -> { any_of_state(["created", "running"]) }

  aasm column: 'aasm_state' do
    state :created, initial: true
    state :running, enter: :enter_running, after_enter: :after_enter_running
    state :stopped, enter: :enter_stopped, after_enter: :after_enter_stopped
    state :finished, enter: :enter_finished, after_enter: :after_enter_finished

    event :start, :after_commit => :after_commit_event_start do
      transitions :from => :created, :to => :running, :guard => :can_start?
    end

    event :stop, :after_commit => :after_commit_event_stop do
      transitions :from => [:created, :running, :stopped], :to => :stopped
    end

    event :finish, :after_commit => :after_commit_event_finish do
      transitions :from => :running, :to => :finished, :guard => :can_finish?
      transitions :from => :running, :to => :stopped
      transitions :from => :finished, :to => :finished
    end
  end

  before_validation :set_ingest_iteration_from_ingest, on: :create
  before_validation :set_server_from_instance_id
  after_commit :after_enter_created, on: :create
  after_commit :update_ingest_if_changed

  class << self
    def generate_uid; SecureRandom.uuid; end
  end

  def worker_class
    worker_name.classify.constantize if worker_name.present?
  rescue NameError
    nil
  end

  def related_ingest_stage
    @related_ingest_stage ||= begin
      if ingest && ingest.respond_to?(:stages) && !!worker_class
        ingest_stage = worker_name.split("/").last.gsub(/_worker$/, "_stage").try(:to_sym)
        ingest.stages.include?(ingest_stage) ? ingest_stage : nil
      end
    end
  end

  def related_ingest_stage?
    !!related_ingest_stage
  end

  def could_forward_ingest_stage?
    result = false
    if related_ingest_stage && related_ingest_stage == ingest.send(:stage_after, ingest.stage)
      result = true
    end
    result
  end

  protected

  def set_ingest_iteration_from_ingest
    self.ingest_iteration ||= ingest.iteration if ingest
  end

  def set_server_from_instance_id
    if instance_id && changes[:instance_id] && !server_id
      if server_from_instance_id = Ingest::Server.find_by_instance_id(instance_id)
        self.server = server_from_instance_id
      end
    elsif server_id && changes[:server_id]
      self.instance_id = server.instance_id
    end
  end

  private

  def after_enter_created
    Ingest::Server::RestartJob.perform_later
  end

  def after_commit_event_start; end
  def after_commit_event_stop; end
  def after_commit_event_finish; end

  def enter_running
    self.started_at = Time.zone.now
  end

  def after_enter_running
    if ingest
      attrs = {busy: true}
      attrs.merge!({status: Ingest::STATE_STARTED}) if ingest.starting?
      attrs.merge!({event: 'forward_stage'}) if could_forward_ingest_stage?
      ingest.update_attributes(attrs) if attrs.present?
    end
  end

  def enter_stopped
    self.stopped_at = Time.zone.now
  end

  def after_enter_stopped
    if ingest && ingest_iteration == ingest.iteration
      attrs = {busy: false}
      attrs.merge!({event: "stop"}) if related_ingest_stage?
      ingest.update_attributes(attrs) if attrs.present?
    end
  end

  def enter_finished
    self.finished_at = Time.zone.now
  end

  def after_enter_finished
    if ingest && ingest_iteration == ingest.iteration
      ingest.update_attributes({busy: false})
      if not_terminate? && ingest.respond_to?(:trigger_next_stage_with!)
        # continue with next stage
        ingest.trigger_next_stage_with!(related_ingest_stage)
      elsif (ingest.removing? || ingest.resetting? || ingest.stopping?) && terminate?
        # sets ingest state to stopped | reset | removed
        Ingest::ProcessJob.perform_later(ingest.id)
      end
    end
  end

  def can_start?
    if ingest
      (ingest.starting? || ingest.started?) && ingest.not_terminate?
    else
      true
    end
  end

  def update_ingest_if_changed
    ingest.save if ingest && ingest.changed?
  end

  def terminate?
    !!ingest.terminate
  end

  def not_terminate?
    !terminate?
  end

  def can_finish?
    if ingest
      ingest_iteration == ingest.iteration && not_terminate?
    else
      true
    end
  end
end
