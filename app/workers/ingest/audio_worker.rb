require 'rubygems'
require 'aws-sdk'

class Ingest::AudioWorker
  include Sidekiq::Worker
  sidekiq_options :queue => :default, :retry => false, :backtrace => true

  STAGES = {
    :initialize                                  => 0,
    :move_object_from_inbound_to_outbound_bucket => 1,
    :download_object_from_outbound_bucket        => 2,
    :transcode                                   => 3,
    :cleanup                                     => 4
  }
  
  def initialize
    AWS.config(
      :access_key_id     => APP_CONFIG['S3_KEY'],    # '*** Provide access key ***'
      :secret_access_key => APP_CONFIG['S3_SECRET']  # '*** Provide secret key ***'
    )
  end
  
  def perform(ingest_id, options = {})
    options.symbolize_keys!
    @ingest = Ingest.find(ingest_id)
    # @ingest.process!
    
    # Execute stages
    Ingest::AudioWorker::STAGES.keys.each do |stage|
      send("#{stage}!".to_sym)
    end
    
    # @ingest.finish!
  rescue Exception => ex
    @ingest.fail! if @ingest
    logger(ex)
    raise ex
  end

  def initialize!
    @ingest.update_attribute(:stage, "initialize") unless @ingest.stage
  end

  def move_object_from_inbound_to_outbound_bucket!
    stage! :move_object_from_inbound_to_outbound_bucket, "object key #{@ingest.s3_key}" do
      # Get an instance of the S3 interface.
      s3 = AWS::S3.new

      # Copy the object.
      s3.buckets[APP_CONFIG['S3_INBOUND_BUCKET']].objects[@ingest.s3_key].copy_to(@ingest.s3_key, 
        :bucket_name => APP_CONFIG['S3_OUTBOUND_BUCKET'])

      # Update ingest reference
      update_s3_url_with File.join(APP_CONFIG['S3_URL'], APP_CONFIG['S3_OUTBOUND_BUCKET'], @ingest.s3_key)

      # Deleting inbound object.
      s3.buckets[APP_CONFIG['S3_INBOUND_BUCKET']].objects.delete(@ingest.s3_key)
    end
  end

  def download_object_from_outbound_bucket!
    stage! :download_object_from_outbound_bucket do
    end
  end
  
  def transcode!
    stage! :transcode do
    end
  end

  def cleanup!
    stage! :cleanup do
    end
  end
  
  protected
  
  def stage!(stage_name, message = nil)
    if @ingest.stage && Ingest::AudioWorker::STAGES[stage_name.to_sym] > Ingest::AudioWorker::STAGES[@ingest.stage.to_sym]
      log! stage_name, message_with("starting", stage_name, message)
      @ingest.update_attribute(:stage, stage_name.to_s) if @ingest
      yield if block_given?
      log! stage_name, message_with("finished", stage_name, message) if block_given?
    end
  end

  def message_with(noun, stage_name, message = nil)
    if message 
      "*** #{noun} #{stage_name.to_s.upcase} at #{Time.now.utc}: #{message}"
    else
      "*** #{noun} #{stage_name.to_s.upcase} at #{Time.now.utc}"
    end
  end

  def progress!(percent, message = nil)
    log! @ingest.stage, message if @ingest && message
    @ingest.update_attribute(:progress, percent)
  end
  
  def log!(stage_name, message)
    @ingest.log! stage_name, message if @ingest
  end
  
  def update_s3_url_with(url)
    @ingest.upload.update_attribute :s3_url, url if @ingest && @ingest.upload
  end
  
  def logger(exception)
    errors = ""
    errors += ("=" * 80) + "\n"
    errors += exception.message + "\n"
    errors += ("=" * 80) + "\n"
    errors += exception.backtrace.join("\n")
    errors += ("=" * 80) + "\n"
    log!(@ingest.stage || :worker, errors)
    Rails.logger.error errors
  end
end