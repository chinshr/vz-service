class Ingest::AudioIngest < ::Ingest::TranscribableIngest
  class << self
    def generate_uid
      "ai-#{super}"
    end
  end
end
