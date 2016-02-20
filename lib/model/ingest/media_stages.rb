module Model::Ingest::MediaStages
  PROGRESS = {harvest_stage: 10, transcode_stage: 20,
    split_stage: 30, archive_stage: 90}

  extend ActiveSupport::Concern

  included do
    attr_writer :trigger

    # stage state machine
    aasm :stage, column: 'aasm_stage', whiny_transitions: true do
      state :begin_stage, initial: true
      state :harvest_stage
      state :transcode_stage
      state :split_stage
      state :archive_stage
      state :end_stage, enter: :enter_end_stage, after_enter: :after_enter_end_stage

      event :forward_to_harvest_stage, after: :after_event_forward_stage, after_commit: :after_commit_event_forward_stage do
        transitions :from => :begin_stage, :to => :harvest_stage, :guard => :can_forward_stage?
      end

      event :forward_to_transcode_stage, after: :after_event_forward_stage, after_commit: :after_commit_event_forward_stage do
        transitions :from => :harvest_stage, :to => :transcode_stage, :guard => :can_forward_stage?
      end

      event :forward_to_split_stage, after: :after_event_forward_stage, after_commit: :after_commit_event_forward_stage do
        transitions :from => :transcode_stage, :to => :split_stage, :guard => :can_forward_stage?
      end

      event :forward_to_archive_stage, after: :after_event_forward_stage, after_commit: :after_commit_event_forward_stage do
        transitions :from => :split_stage, :to => :archive_stage, :guard => :can_forward_stage?
      end

      event :reset_stage do
        transitions :from => [:begin_stage, :harvest_stage, :transcode_stage, :split_stage, :archive_stage, :end_stage], :to => :begin_stage
      end

      event :fast_forward_stage do
        transitions :from => [:begin_stage, :harvest_stage, :transcode_stage, :split_stage, :archive_stage, :end_stage], :to => :end_stage
      end
    end

    after_commit :after_commit_set_busy
    after_commit :after_commit_trigger_stage_async
  end

  module ClassMethods

    # E.g. [:begin_stage, :archive_stage, ..., :end_stage]
    def stages
      aasm(:stage).states.map(&:name)
    end

    # E.g. ['begin', 'archive', ..., 'end']
    def stage_names
      stages.map {|s| stage_trunk_name(s) }
    end

    def worker_class_from_stage(stage_or_stage_name)
      trunk_name = stage_trunk_name(stage_or_stage_name)
      constant_name = "#{trunk_name}_worker".classify
      "Ingest::MediaIngest::#{constant_name}".constantize
    rescue NameError => ex
      nil
    end

    private

    # E.g. :archive_stage -> 'archive'
    def stage_trunk_name(name)
      "#{name}".gsub(/_stage/i, '') if name
    end
  end

  # E.g. [:begin_stage, :harvest_stage, ..., :end_stage]
  def stages
    self.class.stages
  end

  def stage
    aasm(:stage).current_state
  end

  def events
    super + aasm(:stage).events.map(&:name)
  end

  def busy=(value)
    @recently_busy = value
  end

  protected

  def can_forward_stage?
    not_terminated? && not_busy?
  end

  def trigger_next_stage_with!(stage_or_stage_name)
    result = false
    if next_stage = stage_after(stage_or_stage_name)
      if :end_stage == next_stage
        Ingest::MediaIngest::EndJob.perform_later(self.id)
      elsif worker_class = self.class.worker_class_from_stage(next_stage)
        worker_class.perform_workflow(self.id)
        result = true
      end
    end
    result
  end

  def after_commit_set_busy
    if @recently_busy == true || @recently_busy == false
      update_column(:busy, !!@recently_busy)
      @recently_busy = nil
    end
    true # make sure we don't stop here
  end

  def after_commit_event_start
    super
    # allocate server
    Ingest::StartJob.perform_later(self.id) unless Rails.env.development?
    if begin_stage?
      # start workflow from the beginning
      trigger_next_stage_with!(stage)
    elsif rewind_stage!
      # or, restart from where it was stopped at
      trigger_next_stage_with!(stage)
    end
    true # make sure we don't stop here
  end

  def after_commit_trigger_stage_async
    trigger_next_stage_with!(@trigger)
    true # make sure we don't stop here
  end

  def after_enter_restarting
    super
    after_commit_event_start
  end

  def enter_finished
    super
    Ingest::AudioMailer.finished_processing(self).deliver if user
  end

  def enter_reset
    super
    reset_stage
  end

  private

  def enter_end_stage
    self.progress = 100
  end

  def after_enter_end_stage
    finish!
  end

  # TODO: workaround, because after_commit does not fire for event=
  def after_event_forward_stage
    self.progress = PROGRESS[stage] if stage && PROGRESS[stage]
  end

  def after_commit_event_forward_stage
    update_attribute(:progress, PROGRESS[stage]) if stage && PROGRESS[stage]
  end

  def source_stage(stage_or_stage_name)
    stages.find {|s| s.match(/#{stage_or_stage_name.to_s}/i) } if stage_or_stage_name
  end

  # aka next_stage_after
  def stage_after(stage_or_stage_name)
    source = source_stage(stage_or_stage_name)
    stages[stages.index(source) + 1] if source && stages.index(source)
  end

  # aka previous_stage_before
  def stage_before(stage_or_stage_name)
    source = source_stage(stage_or_stage_name)
    stages[stages.index(source) - 1] if source && stages.index(source) && stages.index(source) > 0
  end

  def rewind_stage!
    if previous_stage = stage_before(stage)
      update_attributes(aasm_stage: previous_stage)
    end
  end
end