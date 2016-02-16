class Upload::MediaUpload < Upload
  include Model::MediaHelper

  delegate :document, to: :ingest_or_build_ingest_and_associations, allow_nil: true
  delegate :document_id, to: :ingest_or_build_ingest_and_associations, allow_nil: true

  delegate :title, to: :ingest_or_build_ingest_and_associations, allow_nil: true
  delegate :title=, to: :ingest_or_build_ingest_and_associations, allow_nil: true

  delegate :description, to: :ingest_or_build_ingest_and_associations, allow_nil: true
  delegate :description=, to: :ingest_or_build_ingest_and_associations, allow_nil: true

  delegate :tag_list, to: :ingest_or_build_ingest_and_associations, allow_nil: true
  delegate :tag_list=, to: :ingest_or_build_ingest_and_associations, allow_nil: true

  delegate :locale, to: :ingest_or_build_ingest_and_associations, allow_nil: true
  delegate :locale=, to: :ingest_or_build_ingest_and_associations, allow_nil: true

  delegate :use_source_annotations, to: :ingest_or_build_ingest_and_associations, allow_nil: true
  delegate :use_source_annotations=, to: :ingest_or_build_ingest_and_associations, allow_nil: true

  delegate :handle, to: :ingest_or_build_ingest_and_associations, allow_nil: true
  delegate :handle=, to: :ingest_or_build_ingest_and_associations, allow_nil: true

  delegate :slug, to: :document, allow_nil: true
  delegate :slug_id, to: :document, allow_nil: true
  delegate :published_path, to: :document, allow_nil: true

  delegate :privacy, to: :document, allow_nil: true
  delegate :privacy=, to: :document, allow_nil: true

  delegate :accessibility, to: :document, allow_nil: true
  delegate :accessibility=, to: :document, allow_nil: true

  delegate :images, to: :document, allow_nil: true

  validates :title, presence: true, on: :update
  validate :valid_media_source_url, on: :create

  # private scopes
  scope :started, -> { any_of_status(Ingest::STATES[:started]) }
  scope :stopped, -> { any_of_status(Ingest::STATES[:stopped]) }
  scope :reset, -> { any_of_status(Ingest::STATES[:reset]) }
  scope :removed, -> { any_of_status(Ingest::STATES[:removed]) }
  scope :finished, -> { any_of_status(Ingest::STATES[:finished]) }
  scope :most_recent, -> (n = 5) { order("uploads.created_at DESC").limit(n) }

  after_initialize :build_ingest_and_associations
  after_commit :save_ingest_and_document

  class << self
    alias_method :accepted_file_type?, :valid_media_content_type?

    def accepted_audio_file_type?(file_type)
      !!(file_type && file_type.match(/^(audio)\/?.*$/))
    end

    def accepted_video_file_type?(file_type)
      !!(file_type && file_type.match(/^(video)\/?.*$/))
    end

    def accepted_media_file_type?(file_type)
      accepted_audio_file_type?(file_type) || accepted_video_file_type?(file_type)
    end

  end

  def recorded_at
    self[:recorded_at] || self.created_at
  end

  protected

  def build_ingest_and_associations
    build_ingest(type: "Ingest::MediaIngest", upload: self,
      document: Document.new) unless ingest
  end

  def save_ingest_and_document
    if ingest
      locale_changed = has_locale_recently_changed?
      ingest.document.save if ingest.document && ingest.document.changed?
      ingest.save if ingest.new_record? || ingest.changed?
    end
  ensure
    if locale_changed
      ingest.restart! if ingest.may_restart?
    else
      ingest.start! if ingest.may_start?
    end
  end

  def remove_ingest
    ingest.remove! if ingest.reload
  end

  def has_locale_recently_changed?
    return !!ingest.document.changes[:locale] if ingest.document
    false
  end

end
