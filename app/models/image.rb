class Image < ActiveRecord::Base
  include Model::Filter
  include Model::Uid
  include Model::CDN
  include Model::Iteration

  delegate :width, to: :image_format, allow_nil: true
  delegate :height, to: :image_format, allow_nil: true
  delegate :format, to: :image_format, allow_nil: true
  delegate :aspect_ratio, to: :image_format, allow_nil: true

  belongs_to :image_format, class_name: "Image::ImageFormat"
  belongs_to :ingest

  validates :image_format_id, presence: true
  validates :path, presence: true
  validates :size, numericality: { integer_only: true, greater_than: 0 }
  validates :iteration, numericality: { integer_only: true, greater_than_or_equal_to: 0 }

  filtered_scopes :ingest_image_id
  scope :ingest_image_id, -> (param) { joins(:ingest).where(:ingest => {:id => param}) }

  after_save :touch_ingestable

  class << self

    def generate_uid
      SecureRandom.uuid
    end

  end

  def assets_base_url
    File.join(APP_CONFIG['INGEST_IMAGE_ASSET_HOST'], ingest.s3_origin_bucket_name)
  end

  # This is used to invalidate the media cache key.
  def touch_ingestable
    ingest.try(:ingestable).try(:touch)
  end

  def destroy_with_job
    update_attribute(:removed_at, Time.zone.now)
    Image::RemoveJob.perform_later(self.id)
  end
  alias_method_chain :destroy, :job
end
