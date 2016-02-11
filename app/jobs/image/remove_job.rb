class Image::RemoveJob < ActiveJob::Base
  include Job::Helper

  queue_as :default

  def perform(image_id)
    if image = Image.find(image_id)
      s3_delete_object_if_exists(image.ingest.s3_origin_bucket_name,
        image.path)

      image.destroy_without_job
    end
  end
end