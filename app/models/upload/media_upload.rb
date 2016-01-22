class Upload::MediaUpload < Upload
  include Model::MediaHelper

  TARGET_MAX_NUMBER_OF_KEYWORDS = 100

  delegate :title, to: :ingest_or_build_ingest_and_document, allow_nil: true
  delegate :title=, to: :ingest_or_build_ingest_and_document, allow_nil: true

  delegate :description, to: :ingest_or_build_ingest_and_document, allow_nil: true
  delegate :description=, to: :ingest_or_build_ingest_and_document, allow_nil: true

  delegate :privacy, to: :ingest_or_build_ingest_and_document, allow_nil: true
  delegate :privacy=, to: :ingest_or_build_ingest_and_document, allow_nil: true

  delegate :tag_list, to: :ingest_or_build_ingest_and_document, allow_nil: true
  delegate :tag_list=, to: :ingest_or_build_ingest_and_document, allow_nil: true

  delegate :locale, to: :ingest_or_build_ingest_and_document, allow_nil: true
  delegate :locale=, to: :ingest_or_build_ingest_and_document, allow_nil: true

  delegate :slug, to: :ingest_or_build_ingest_and_document

  delegate :slug_id, to: :ingest_or_build_ingest_and_document

  delegate :use_source_annotations, to: :ingest_or_build_ingest_and_document, allow_nil: true
  delegate :use_source_annotations=, to: :ingest_or_build_ingest_and_document, allow_nil: true

  delegate :handle, to: :ingest_or_build_ingest_and_document, allow_nil: true
  delegate :handle=, to: :ingest_or_build_ingest_and_document, allow_nil: true

  validates :title, presence: true, on: :update
  validate :valid_source_url, on: :create

  # private scopes
  scope :started, -> { any_of_status(Ingest::STATES[:started]) }
  scope :stopped, -> { any_of_status(Ingest::STATES[:stopped]) }
  scope :reset, -> { any_of_status(Ingest::STATES[:reset]) }
  scope :removed, -> { any_of_status(Ingest::STATES[:removed]) }
  scope :finished, -> { any_of_status(Ingest::STATES[:finished]) }
  scope :most_recent, -> (n = 5) { order("uploads.created_at DESC").limit(n) }

  after_initialize :build_ingest_and_document
  before_validation :set_attributes, on: :create
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

  def build_ingest_and_document
    build_ingest(type: "Ingest::MediaIngest", upload: self,
      document: Document.new) unless ingest
  end

  def save_ingest_and_document
    if ingest
      locale_changed = has_locale_recently_changed?
      ingest.document.save if ingest.document && ingest.document.changed?
      ingest.save if ingest.new_record? || ingest.changed?

      if locale_changed
        ingest.restart! if ingest.may_restart?
      else
        ingest.start! if ingest.may_start?
      end
    end
  end

  def remove_ingest
    ingest.remove! if ingest.reload
  end

  def has_locale_recently_changed?
    return !!ingest.document.changes[:locale] if ingest.document
    false
  end

  private

  def target
    @target ||= Model::URI::Target.new(source_url)
  end

  def set_attributes
    set_attributes_from_target
    set_attributes_from_metadata
  end

  def set_attributes_from_target
    if has_source_url? && !has_s3_source_url? && target.valid? && target.resolves?
      self.source_url = target.url
      self.file_type  = target.content_type if self.class.valid_media_content_type?(target.content_type)
      # set metadata
      hash = {}
      hash['target']  = target.metadata unless target.metadata.blank?
      self.metadata  = hash
    end
  end

  def set_attributes_from_metadata
    # title
    if title.blank?
      if metadata['target'] && metadata['target']['title']
        self.title = humanize_path(metadata['target']['title'])
      elsif file_name.present?
        self.title = humanize_path(file_name)
      elsif source_url.present?
        self.title = humanize_url(source_url)
      end
    end
    # description
    if description.blank?
      if metadata['target'] && metadata['target']['description'].present?
        self.description = metadata['target']['description']
      end
    end
    # tags
    if tag_list.blank?
      if metadata['target'] && metadata['target']['keywords'].present?
        self.tag_list = metadata['target']['keywords'].slice(0, TARGET_MAX_NUMBER_OF_KEYWORDS)
      end
    end
  end

  def valid_source_url
    errors.add(:source_url, :invalid) unless target.valid?

    if has_s3_source_url?
      errors.add(:file_name, :presence) unless file_name.present?
      errors.add(:file_type, :media_expected) unless valid_media_file_type?
    else
      errors.add(:source_url, :unresolved, error: target.error) if target.valid? && !target.resolves?
      if target.valid? && target.resolves? && !(target.valid_media_service? || target.valid_media_content_type?)
        errors.add(:source_url, :unknown_content_type_or_video_service)
      end
    end
  end
end
