class Ingest::Audio < ::Ingest
  delegate :title, to: :ingestable
  delegate :title=, to: :ingestable
  
  delegate :description, to: :ingestable
  delegate :description=, to: :ingestable

  delegate :locale, to: :ingestable
  delegate :locale=, to: :ingestable

  delegate :privacy, to: :ingestable
  delegate :privacy=, to: :ingestable

  delegate :user, to: :ingestable
  delegate :user=, to: :ingestable
  
  delegate :slug, to: :ingestable

  protected

  def enter_starting
    super
  end
  
  def after_enter_starting
    super
    Ingest::AudioWorker.perform_async(self.id)
  end
  
  def after_enter_resetting
    super
    Ingest::AudioWorker.perform_async(self.id)
  end

  def after_enter_stopping
    super
    Ingest::AudioWorker.perform_async(self.id)
  end
  
  def after_exit_restarting
    super
    # segments.destroy_all
  end
  
  def after_enter_restarting
    super
    Ingest::AudioWorker.perform_async(self.id)
  end
  
  def enter_finished
    super
    Ingest::AudioMailer.finished_processing(self).deliver if user
  end
  
end
