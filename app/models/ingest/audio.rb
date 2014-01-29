class Ingest::Audio < ::Ingest
  has_many :segments, class_name: "Ingest::Audio::Segment", foreign_key: :ingest_id, dependent: :destroy
  
  delegate :title, to: :ingestable
  delegate :title=, to: :ingestable
  
  delegate :description, to: :ingestable
  delegate :description=, to: :ingestable

  delegate :locale, to: :ingestable
  delegate :locale=, to: :ingestable

  delegate :privacy, to: :ingestable
  delegate :privacy=, to: :ingestable
  
  delegate :slug, to: :ingestable

  def score
    segments.average(:best_score) 
  end
  
  def duration
    segments.sum(:duration) 
  end
  
  protected

  def enter_starting
    super
    self.messages = {}
    self.s3_url   = nil
    segments.destroy_all
  end
  
  def after_enter_starting
    super
    Ingest::AudioWorker.perform_async(self.id)
  end
  
  def enter_after_resetting
    super
    Ingest::AudioWorker.perform_async(self.id)
  end

  def enter_reset
    super
    self.increment(:iteration)
  end

  def enter_after_stopping
    super
    Ingest::AudioWorker.perform_async(self.id)
  end
  
end
