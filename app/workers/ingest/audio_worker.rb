require 'rubygems'
require 'aws-sdk'

class Ingest::AudioWorker
  include Sidekiq::Worker
  sidekiq_options :queue => :default, :retry => false, :backtrace => true

  STAGES = {move_object_from_inbound_to_outbound_bucket: 1, download_object_from_outbound_bucket: 2, transcode: 3, cleanup: 4}
  
  def initialize
    AWS.config(
      :access_key_id     => APP_CONFIG['S3_KEY'],    # '*** Provide access key ***'
      :secret_access_key => APP_CONFIG['S3_SECRET']  # '*** Provide secret key ***'
    )
  end
  
  def perform(ingest_id, options = {})
    options.symbolize_keys!
    @ingest = Ingest.find(ingest_id)
    
    move_object_from_inbound_to_outbound_bucket!
    download_object_from_outbound_bucket!
    transcode!
    cleanup!

    # @ingest.enable!
  rescue Exception => ex
    @ingest.stop! if @ingest
    logger(ex)
    raise ex
  end

  def move_object_from_inbound_to_outbound_bucket!
    stage! :move_object
    
    inbound_bucket_name  = APP_CONFIG['S3_INBOUND_BUCKET']
    outbound_bucket_name = APP_CONFIG['S3_OUTBOUND_BUCKET']
    source_target_key    = @ingest.s3_key

    # Get an instance of the S3 interface.
    s3 = AWS::S3.new

    inbound_bucket  = s3.buckets[inbound_bucket_name]
    outbound_bucket = s3.buckets[outbound_bucket_name]
    inbound_object  = inbound_bucket[source_target_key]
    outbound_object = outbound_bucket[source_target_key]

    # Copy the object.
    inbound_object.copy_to(outbound_object)    

    # Deleting inbound object.
    # inbound_bucket.objects.delete(source_target_key)
    
    log! @ingest.stage, "*** Moving object '#{@ingest.s3_key}' successfully finished."
  end

  def download_object_from_outbound_bucket!
    stage! :download_object_from_outbound_bucket
  end
  
  def transcode!
    stage! :transcode
  end

  def cleanup!
    stage! :cleanup
  end
  
  protected
  
  def stage!(stage_name, message = nil)
    log! message if message
    @ingest.update_attribute(:stage, stage_name)
  end

  def progress!(percent, message = nil)
    log! message if message
    @ingest.update_attribute(:progress, percent)
  end
  
  def logger(exception)
    errors = ""
    errors += ("=" * 80) + "\n"
    errors += exception.message + "\n"
    errors += ("=" * 80) + "\n"
    errors += exception.backtrace.join("\n")
    errors += ("=" * 80) + "\n"
    @ingest.log!(@ingest.stage || :setup, errors) if @ingest
    Rails.logger.error errors
  end
end