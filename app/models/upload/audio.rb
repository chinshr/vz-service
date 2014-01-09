class Upload::Audio < ::Upload
  delegate :title, to: :ingest
  delegate :title=, to: :ingest
  
  delegate :description, to: :ingest
  delegate :description=, to: :ingest
  
  delegate :status, to: :ingest
  delegate :slug, to: :ingest
  
  validate :audio_file_type
  
  protected
  
  def audio_file_type
    errors.add(:file_type, :audio_expected) if !file_type || !file_type.match(/^(audio)\/?.*$/)
  end
  
  def create_ingest
    case file_type
    when /audio/
      Ingest::Audio.create(upload: self, ingestable: Document.create(title: human_name))
    end unless new_record?
  end
  
end
