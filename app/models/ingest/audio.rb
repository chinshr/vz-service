class Ingest::Audio < ::Ingest
  delegate :title, to: :ingestable
  delegate :title=, to: :ingestable
  
  delegate :description, to: :ingestable
  delegate :description=, to: :ingestable
  
  delegate :slug, to: :ingestable
end
