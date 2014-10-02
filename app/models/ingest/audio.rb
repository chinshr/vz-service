class Ingest::Audio < ::Ingest
  delegate :title, to: :ingestable
  delegate :title=, to: :ingestable
  
  delegate :description, to: :ingestable
  delegate :description=, to: :ingestable

  delegate :tag_list, to: :ingestable
  delegate :tag_list=, to: :ingestable

  delegate :locale, to: :ingestable
  delegate :locale=, to: :ingestable

  delegate :privacy, to: :ingestable
  delegate :privacy=, to: :ingestable

  delegate :user, to: :ingestable
  delegate :user=, to: :ingestable
  
  delegate :slug, to: :ingestable

  after_commit :perform_async

  protected

  def perform_async
    Ingest::AudioWorker.perform_async(self.id) if perform_async_scheduled?
    clear_perform_async!
  end
  
  def after_enter_starting
    super
    schedule_perform_async!
  end
  
  def after_enter_resetting
    super
    schedule_perform_async!
  end

  def after_enter_stopping
    super
    schedule_perform_async!
  end
  
  def after_enter_restarting
    super
    ::Ingest::AudioWorker.perform_async(self.id)
  end
  
  def enter_finished
    super

    # send email
    ::Ingest::AudioMailer.finished_processing(self).deliver if user
  end

  protected
  
  def perform_async_scheduled?
    !!@schedule_perform_async
  end

  def schedule_perform_async!
    @schedule_perform_async = true
  end

  def clear_perform_async!
    @schedule_perform_async = nil
  end
end
