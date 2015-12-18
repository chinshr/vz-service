class Upload::DeleteJob < ActiveJob::Base
  include Job::Helper
  queue_as :default

  def perform(upload_id)
    if @upload = Upload.find_by_id(upload_id)
      s3_delete_object_if_exists(APP_CONFIG['S3_INBOUND_BUCKET'],
        @upload.handle)
      @upload.delete
    end
  end
end
