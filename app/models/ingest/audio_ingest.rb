class Ingest::AudioIngest < Ingest
  include Model::Ingest::MediaIngest

  class << self
    def generate_uid
      "ai-#{super}"
    end
  end
end
