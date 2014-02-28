class Upload::Audio < ::Upload
  delegate :title, to: :ingest, allow_nil: true
  delegate :title=, to: :ingest, allow_nil: true
  
  delegate :description, to: :ingest, allow_nil: true
  delegate :description=, to: :ingest, allow_nil: true
  
  delegate :locale, to: :ingest, allow_nil: true
  delegate :locale=, to: :ingest, allow_nil: true

  delegate :privacy, to: :ingest, allow_nil: true
  delegate :privacy=, to: :ingest, allow_nil: true

  delegate :user, to: :ingest, allow_nil: true
  delegate :user=, to: :ingest, allow_nil: true
  
  delegate :status, to: :ingest
  delegate :slug, to: :ingest
  delegate :progress, to: :ingest
  
  validates :title, presence: true, on: :update
  validate :audio_file_type
  
  after_save :save_ingest_and_document
  after_initialize :build_ingest_and_document
  before_validation :set_title, on: :create

  class << self
    def accepted_audio_file_type?(file_type)
      !!(file_type && file_type.match(/^(audio)\/?.*$/))
    end
  end

  def has_locale_recently_changed?
    return !!ingest.ingestable.changes[:locale] if ingest.ingestable
    false
  end
  
  protected
  
  def audio_file_type
    errors.add(:file_type, :audio_expected) unless Upload::Audio.accepted_audio_file_type?(file_type)
  end
  
  def build_ingest_and_document
    build_ingest(type: "Ingest::Audio", upload: self, 
      ingestable: ::Document.new(title: humanized_file_name, locale: "en-US", privacy: :public)) unless ingest
  end
  
  def set_title
    self.title = humanized_file_name if title.blank?
  end
  
  def save_ingest_and_document
    if ingest
      locale_changed = has_locale_recently_changed?
      ingest.ingestable.save if ingest.ingestable && ingest.ingestable.changed?
      ingest.save if ingest.changed?
      
      if !new_record? && has_s3_url?
        if locale_changed
          ingest.restart! if ingest.may_restart?
        else
          ingest.start! if ingest.may_start?
        end
      end
    end
  end
end
