class Upload::Audio < ::Upload
  validate :audio_file_type

  class << self
    def accepted_audio_file_type?(file_type)
      !!(file_type && file_type.match(/^(audio)\/?.*$/))
    end
  end

  protected

  def audio_file_type
    errors.add(:file_type, :audio_expected) unless Upload::Audio.accepted_audio_file_type?(file_type)
  end

  def build_ingest_and_document
    build_ingest(type: "Ingest::Audio", upload: self,
      document: ::Document.new(title: humanized_file_name, locale: "en-US", privacy: :public)) unless ingest
  end
end
