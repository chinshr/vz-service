class Ingest::DeleteJob < ApplicationJob
  include Job::Helper

  queue_as :default

  def perform(ingest_id)
    if @ingest = Ingest.with_deleted.find_by_id(ingest_id)
      # remove uploaded file
      s3_delete_object_if_exists(
        @ingest.s3_upload_bucket_name,
        @ingest.handle)
      # remove all origin files
      s3_delete_objects_with_prefix(
        @ingest.s3_origin_bucket_name,
        @ingest.uid)
      # destroy record
      @ingest.really_destroy!
    end
  end
end
