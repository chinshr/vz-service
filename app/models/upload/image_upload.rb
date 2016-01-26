class Upload::ImageUpload < Upload
  include Model::ImageHelper

  delegate :ingestable, to: :ingest_or_build_ingest_and_associations, allow_nil: true
  delegate :ingestable=, to: :ingest_or_build_ingest_and_associations, allow_nil: true
  delegate :ingestable_id, to: :ingest_or_build_ingest_and_associations, allow_nil: true
  delegate :ingestable_id=, to: :ingest_or_build_ingest_and_associations, allow_nil: true
  delegate :ingestable_type, to: :ingest_or_build_ingest_and_associations, allow_nil: true
  delegate :ingestable_type=, to: :ingest_or_build_ingest_and_associations, allow_nil: true

  validate :valid_source_url, on: :create

  after_initialize :build_ingest_and_associations
  after_commit :save_ingest

  def s3_origin_bucket_name
    APP_CONFIG['S3_ASSETS_BUCKET']
  end

  protected

  def valid_source_url
    errors.add(:source_url, :invalid) unless target.valid?

    if has_s3_source_url?
      errors.add(:file_name, :presence) unless file_name.present?
      errors.add(:file_type, :media_expected) unless valid_image_file_type?
    else
      errors.add(:source_url, :unresolved, error: target.error) if target.valid? && !target.resolves?
      if target.valid? && target.resolves? && !target.valid_image_content_type?
        errors.add(:source_url, :unknown_content_type_or_video_service)
      end
    end
  end

  # override
  def build_ingest_and_associations
    build_ingest({type: "Ingest::ImageIngest", upload: self}) unless ingest
  end

  def save_ingest
    if ingest
      ingest.save if ingest.new_record? || ingest.changed?
      ingest.start! if ingest.may_start?
    end
  end

  private

  def target
    @target ||= Model::URI::Target.new(source_url)
  end

end
