class Upload::Audio < ::Upload
  delegate :title, to: :ingest, allow_nil: true
  delegate :title=, to: :ingest, allow_nil: true
  
  delegate :description, to: :ingest, allow_nil: true
  delegate :description=, to: :ingest, allow_nil: true
  
  delegate :locale, to: :ingest, allow_nil: true
  delegate :locale=, to: :ingest, allow_nil: true

  delegate :privacy, to: :ingest, allow_nil: true
  delegate :privacy=, to: :ingest, allow_nil: true
  
  delegate :status, to: :ingest
  delegate :slug, to: :ingest
  delegate :progress, to: :ingest
  
  validates :title, presence: true, on: :update
  validate :audio_file_type
  
  after_save :save_ingest_and_document
  after_initialize :build_ingest_and_document
  before_validation :set_ingest_and_document

  protected
  
  def audio_file_type
    errors.add(:file_type, :audio_expected) if !file_type || !file_type.match(/^(audio)\/?.*$/)
  end
  
  def build_ingest_and_document
    build_ingest(type: "Ingest::Audio", upload: self, 
      ingestable: ::Document.new(title: humanized_file_name, locale: "en-US", privacy: :public)) unless ingest
  end
  
  def set_ingest_and_document
    self.title = humanized_file_name if title.blank?
  end
  
  def save_ingest_and_document
    ingest.ingestable.save if ingest && ingest.ingestable && ingest.ingestable.changed?
    ingest.save if ingest && ingest.changed?
  end
end
