class Image::DeleteJob < ActiveJob::Base
  include Job::Helper

  queue_as :default

  def perform(image_id)
    if image = Image.with_deleted.find_by_id(image_id)
      s3_delete_object_if_exists(image.ingest.s3_origin_bucket_name,
        image.path)
      image.really_destroy!
    end
  end
end