class Ingest::RemoveJob < ActiveJob::Base
  include Job::Helper

  queue_as :default

  RETRIES      = 5
  WAIT_IN_SECS = 1.minute

  def perform(ingest_id, options = {})
    options = options.reverse_merge({retries: RETRIES})
    if @ingest = Ingest.find(ingest_id)
      if @ingest.not_busy?
        @ingest.with_lock do
          # remove uploaded file
          s3_delete_object_if_exists(APP_CONFIG['S3_INBOUND_BUCKET'],
            @ingest.handle)
          # remove all origin files
          s3_delete_objects_with_prefix(APP_CONFIG['S3_OUTBOUND_BUCKET'],
            @ingest.uid)
          # move state to 'removed'
          @ingest.process!
        end
      else
        Ingest::RemoveJob.set(wait: WAIT_IN_SECS).perform_later(ingest_id, {retries: options[:retries] - 1}) if options[:retries] > 0
      end
    end
  end
end