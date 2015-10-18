class Ingest::TranscribableIngest < ::Ingest
  delegate :title, to: :document
  delegate :title=, to: :document

  delegate :description, to: :document
  delegate :description=, to: :document

  delegate :tag_list, to: :document
  delegate :tag_list=, to: :document

  delegate :locale, to: :document
  delegate :locale=, to: :document

  delegate :privacy, to: :document
  delegate :privacy=, to: :document

  delegate :user, to: :document
  delegate :user=, to: :document

  delegate :slug, to: :document
  delegate :slug_id, to: :document

  after_commit :perform_async

  protected

  # is called by after_commit as we need to wait
  # to do a specific background job until the record
  # has been commited to the DB and not at the time
  # the state is changed.
  def perform_async
    if perform_async_start_scheduled?
      # Allocate server
      Ingest::StartJob.perform_later(self.id)
      # Start CPW workflow
      Ingest::StartWorker.perform_workflow(self.id)
    elsif perform_async_stop_scheduled?
      Ingest::StopWorker.perform_async(self.id, {force: true})
    elsif perform_async_reset_scheduled?
      Ingest::ResetWorker.perform_async(self.id, {force: true})
    elsif perform_async_remove_scheduled?
      Ingest::RemoveWorker.perform_async(self.id, {force: true})
    end

    clear_all_perform_async!
  end

  def after_enter_starting
    super
    schedule_perform_async_start!
  end

  def after_enter_resetting
    super
    schedule_perform_async_reset!
  end

  def after_enter_stopping
    super
    schedule_perform_async_stop!
  end

  def after_enter_restarting
    super
    Ingest::StartWorker.perform_workflow(self.id)
  end

  def enter_finished
    super
    Ingest::AudioMailer.finished_processing(self).deliver if user
  end

  def after_enter_removing
    super
    schedule_perform_async_remove!
  end

  def perform_async_start_scheduled?
    !!@schedule_perform_async_start
  end

  def schedule_perform_async_start!
    @schedule_perform_async_start = true
  end

  def perform_async_stop_scheduled?
    !!@schedule_perform_async_stop
  end

  def schedule_perform_async_stop!
    @schedule_perform_async_stop = true
  end

  def perform_async_reset_scheduled?
    !!@schedule_perform_async_reset
  end

  def schedule_perform_async_reset!
    @schedule_perform_async_reset = true
  end

  def perform_async_remove_scheduled?
    !!@schedule_perform_async_remove
  end

  def schedule_perform_async_remove!
    @schedule_perform_async_remove = true
  end

  def clear_all_perform_async!
    @schedule_perform_async_start  = nil
    @schedule_perform_async_stop   = nil
    @schedule_perform_async_reset  = nil
    @schedule_perform_async_remove = nil
  end
end
