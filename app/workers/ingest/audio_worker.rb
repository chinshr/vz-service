require 'rubygems'
require 'aws-sdk'
require "speech"

class Ingest::AudioWorker
  include Sidekiq::Worker
  sidekiq_options :queue => :default, :retry => false, :backtrace => true

  STAGES = {
    :initialize                                  => 0,
    :copy_object_from_inbound_to_outbound_bucket => 1,
    :download_object_from_outbound_bucket        => 2,
    :transcribe                                  => 3,
    :update_ingestable                           => 4,
    :cleanup                                     => 5,
    :finalized                                   => 6,
  }
  
  def initialize
    AWS.config(
      :access_key_id     => APP_CONFIG['S3_KEY'],    # '*** Provide access key ***'
      :secret_access_key => APP_CONFIG['S3_SECRET']  # '*** Provide secret key ***'
    )
    @s3 = AWS::S3.new
  end
  
  def perform(ingest_id, options = {})
    options.symbolize_keys!
    @ingest = Ingest::Audio.find(ingest_id)
    
    # Check what we have to do?
    case @ingest.state
    when :starting, :stopped, :reset
      # Execute stages
      Ingest::AudioWorker::STAGES.keys.each do |stage|
        send("#{stage}!".to_sym)
      end
    when :resetting, :stopping then @ingest.process!
    when :removing then @ingest.process!
    end
    
  rescue Exception => ex
    @ingest.fail! if @ingest
    logger(ex)
    raise ex
  end

  def initialize!
    stage! :initialize do
      @ingest.process!
      set_progress! 0
    end
  end

  def copy_object_from_inbound_to_outbound_bucket!
    stage! :copy_object_from_inbound_to_outbound_bucket, "object key #{@ingest.s3_key}" do
      # Copy the object.
      s3_copy_object APP_CONFIG['S3_INBOUND_BUCKET'], APP_CONFIG['S3_OUTBOUND_BUCKET'], s3_key

      # Update ingest reference
      update_s3_url_with File.join(APP_CONFIG['S3_URL'], APP_CONFIG['S3_OUTBOUND_BUCKET'], s3_key)

      set_progress! 5
    end
  end

  def download_object_from_outbound_bucket!
    stage! :download_object_from_outbound_bucket do
      s3_download_object(APP_CONFIG['S3_OUTBOUND_BUCKET'], s3_key, audio_filename_fullpath)
      set_progress! 10
    end
  end
  
  def transcribe!
    stage! :transcribe do
      transcribe_file(audio_filename_fullpath)
    end
  end
  
  def update_ingestable!
    stage! :update_ingestable do
      content = @ingest.segments.map {|sg| sg.best_text ? sg.best_text.strip : nil}.compact.join(" ")
      @ingest.ingestable.update_attribute(:content, content)
    end
  end

  def cleanup!
    stage! :cleanup do
      # Delete local file
      File.delete(audio_filename_fullpath) if File.exist? audio_filename_fullpath
      
      # Delete inbound object.
      s3_delete_object(APP_CONFIG['S3_INBOUND_BUCKET'], s3_key)
      
      set_progress! 95
    end
  end
  
  def finalized!
    stage! :finalized do
      @ingest.finish!
      set_progress! 100
    end
  end
  
  protected
  
  def stage!(stage_name, message = nil)
    if can_stage?(stage_name)
      log! stage_name, header_with("starting", stage_name, message)
      @ingest.update_attribute(:stage, stage_name.to_s) if @ingest
      yield if block_given?
      log! stage_name, header_with("finished", stage_name, message) if block_given?
    end
  end
  
  def can_stage?(stage_name)
    if @ingest
      if @ingest.stage && @ingest.started?
        # get on with the next stage
        return Ingest::AudioWorker::STAGES[stage_name.to_sym] > Ingest::AudioWorker::STAGES[@ingest.stage.to_sym]
      elsif @ingest.stage && @ingest.stopped?
        # attempt to re-run current stopped stage
        return Ingest::AudioWorker::STAGES[stage_name.to_sym] >= Ingest::AudioWorker::STAGES[@ingest.stage.to_sym]
      elsif !@ingest.stage
        # initializing
        return true
      end
    end
    false
  end

  def header_with(noun, stage_name, message = nil)
    if message 
      "*** #{noun} #{stage_name.to_s.upcase} at #{Time.now.utc}: #{message}"
    else
      "*** #{noun} #{stage_name.to_s.upcase} at #{Time.now.utc}"
    end
  end

  # set_progress! 10 => 10%
  def set_progress!(percent)
    Ingest.transaction do
      @ingest.lock!
      new_progress = @ingest.progress + percent
      new_progress = new_progress > 100 ? 100 : new_progress
      @ingest.update_attribute(:progress, new_progress)
    end if @ingest
  end

  # set_progress! 10 => 10%
  # increment_progress! 1, 5, 0.8 => 26%
  # increment_progress! 1, 5, 0.8 => 42%
  # ...
  # increment_progress! 1, 5, 0.8 => 90%
  def increment_progress!(counter, denominator, factor = 1.0)
    Ingest.transaction do
      @ingest.lock!
      new_progress = @ingest.progress + (counter / denominator.to_f * factor * 100).round
      new_progress = new_progress > 100 ? 100 : new_progress
      @ingest.update_attribute(:progress, new_progress)
    end if @ingest
  end
  
  def log!(stage_name, message)
    @ingest.log! stage_name, message if @ingest
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
  
  def update_s3_url_with(url)
    @ingest.update_attribute :s3_url, url if @ingest
  end
  
  def s3_key
    @ingest.s3_key if @ingest
  end
  alias_method :audio_filename, :s3_key
  
  def s3_url
    @ingest.s3_url if @ingest
  end

  def audio_filename_fullpath
    if Rails.env.development?
      "#{Rails.root}/tmp/#{audio_filename}"
    else
      "#{Rails.root}/#{audio_filename}"
    end
  end
  
  def s3; @s3; end
  
  def s3_copy_object(source_bucket_name, destination_bucket_name, source_key, destination_key = nil)
    destination_key = source_key if destination_key.blank?
    s3.buckets[source_bucket_name].objects[key].copy_to(key, :bucket_name => destination_bucket_name)
  end
  
  def s3_download_object(source_bucket_name, source_key, destination_filename)
    File.open(destination_filename, 'wb') do |file|
      s3.buckets[source_bucket_name].objects[source_key].read do |chunk|
        file.write(chunk)
      end
    end
  end
  
  def transcribe_file(filename)
    start_time = BigDecimal.new("0.0")
    audio      = Speech::AudioToText.new(filename)
    audio.to_json(3, @ingest.locale) do |chunk|
      end_time = start_time + BigDecimal.new(chunk.duration.to_s)
      @ingest.segments.create(
        :offset      => chunk.offset,
        :duration    => chunk.duration,
        :start_time  => start_time,
        :end_time    => end_time,
        :best_text   => chunk.best_text,
        :best_score  => chunk.best_score,
        :response    => chunk.captured_json
      )
      start_time = end_time
      increment_progress! 1, chunk.splitter.chunks.size, 0.8
    end
  end
  
  def s3_delete_object(bucket_name, key) 
    s3.buckets[bucket_name].objects.delete(key)
  end
  
end