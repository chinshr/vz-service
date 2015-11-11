class Ingest::VideoIngest < Ingest
  include Model::Ingest::MediaIngest

  class << self
    def generate_uid
      "vi-#{super}"
    end
  end

end
