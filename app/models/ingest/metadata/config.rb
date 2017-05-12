class Ingest::Metadata::Config
  include Model::Virtus::ActiveModel

  VERSION = "1.0.0"

  attribute :version, String, default: :current_version, lazy: true

  complex_attribute :transcription, Ingest::Metadata::Config::Transcription, default: {}

  private

  def current_version
    VERSION
  end
end
