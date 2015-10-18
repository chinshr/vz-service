class Ingest::VideoIngest < ::Ingest::TranscribableIngest

  class << self
    def generate_uid
      "vi-#{super}"
    end
  end

end
