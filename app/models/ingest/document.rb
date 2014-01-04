class Ingest::Document < ::Ingest
  delegate :title, to: :ingestable
  delegate :description, to: :ingestable
end
