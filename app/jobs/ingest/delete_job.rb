class Ingest::DeleteJob < ActiveJob::Base
  include Job::Helper

  queue_as :default

  def perform(ingest_id)
    if @ingest = Ingest.find(ingest_id)
      # remove uploaded file
      s3_delete_object_if_exists(
        @ingest.s3_upload_bucket_name,
        @ingest.handle)
      # remove all origin files
      s3_delete_objects_with_prefix(
        @ingest.s3_origin_bucket_name,
        @ingest.uid)
      # delete records
      @ingest.upload.delete if @ingest.upload
      @ingest.delete_without_job
    end
  end
end
