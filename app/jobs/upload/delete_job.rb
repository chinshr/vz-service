class Upload::DeleteJob < ActiveJob::Base
  include Job::Helper
  queue_as :default

  def perform(upload_id)
    if @upload = Upload.find(upload_id)
      s3_delete_object_if_exists(@upload.s3_upload_bucket_name,
        @upload.handle)

      @upload.delete_without_job
    end
  end
end
