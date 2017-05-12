class Ingest::Metadata::Config::Transcription
  include Model::Virtus::ActiveModel

  attribute :engine, String
  attribute :quality, String
  # attribute :use_source_annotations, Boolean, default: false
end
