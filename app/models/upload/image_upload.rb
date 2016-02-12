class Upload::ImageUpload < Upload
  include Model::ImageHelper

  delegate :ingestable, to: :ingest_or_build_ingest_and_associations, allow_nil: true
  delegate :ingestable=, to: :ingest_or_build_ingest_and_associations, allow_nil: true
  delegate :ingestable_id, to: :ingest_or_build_ingest_and_associations, allow_nil: true
  delegate :ingestable_id=, to: :ingest_or_build_ingest_and_associations, allow_nil: true
  delegate :ingestable_type, to: :ingest_or_build_ingest_and_associations, allow_nil: true
  delegate :ingestable_type=, to: :ingest_or_build_ingest_and_associations, allow_nil: true

  validate :valid_image_source_url, on: :create

  after_initialize :build_ingest_and_associations
  after_commit :save_ingest

  def s3_origin_bucket_name
    APP_CONFIG['S3_ASSETS_BUCKET']
  end

  protected

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
end
