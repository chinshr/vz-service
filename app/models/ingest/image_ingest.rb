class Ingest::ImageIngest < Ingest
  include Model::ImageHelper

  delegate :user, to: :ingestable, allow_nil: true

  belongs_to :ingestable, polymorphic: true, touch: true
  has_many :images, -> { where("images.removed_at IS NULL") },
    :class_name => "::Image", :foreign_key => :ingest_id, :dependent => :destroy
  has_many :images_with_removed,
    :class_name => "::Image", :foreign_key => :ingest_id, :dependent => :destroy

  validates :ingestable, presence: true
  validate :valid_image_source_url, on: :create, unless: :has_upload?

  after_validation :set_iteration, on: :create

  def s3_origin_bucket_name
    APP_CONFIG['S3_ASSETS_BUCKET']
  end

  protected

  def after_commit_event_start
    super
    Ingest::ImageIngest::ProcessJob.perform_later(self.id)
  end

  private

  def set_iteration
    self.iteration = (ingestable.image_ingests.maximum(:iteration) || 0) + 1 if ingestable
  end
end
