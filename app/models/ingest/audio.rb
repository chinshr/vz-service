class Ingest::Audio < ::Ingest
  has_many :segments, class_name: "Ingest::Audio::Segment", foreign_key: :ingest_id
  
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
end
