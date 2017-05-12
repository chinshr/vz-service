class Upload::DeleteJob < ApplicationJob
  include Job::Helper
  queue_as :default

  def perform(upload_id)
    if @upload = Upload.with_deleted.find_by_id(upload_id)
      s3_delete_object_if_exists(@upload.s3_upload_bucket_name,
        @upload.handle)
      @upload.really_destroy!
    end
  end
end
