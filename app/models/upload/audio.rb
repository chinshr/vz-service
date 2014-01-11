class Upload::Audio < ::Upload
  delegate :title, to: :ingest, allow_nil: true
  delegate :title=, to: :ingest, allow_nil: true
  
  delegate :description, to: :ingest, allow_nil: true
  delegate :description=, to: :ingest, allow_nil: true
  
  delegate :status, to: :ingest
  delegate :slug, to: :ingest
  
  validates :title, presence: true, on: :update
  validates :description, presence: true, on: :update
  validate :audio_file_type
  
  after_create :create_ingest
  after_save :update_ingest
  
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
  
  def update_ingest
    ingest.ingestable.save if ingest && ingest.ingestable && ingest.ingestable.changed?
    ingest.save if ingest && ingest.changed?
  end
end
