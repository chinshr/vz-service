class Ingest::Audio < ::Ingest
  delegate :title, to: :ingestable
  delegate :title=, to: :ingestable
  
  delegate :description, to: :ingestable
  delegate :description=, to: :ingestable

  delegate :locale, to: :ingestable
  delegate :locale=, to: :ingestable

  delegate :privacy_mask, to: :ingestable
  delegate :privacy_mask=, to: :ingestable
  
  delegate :slug, to: :ingestable
end
