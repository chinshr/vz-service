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
    :remove_upload                               => 5,
    :finalized                                   => 6,
  }
  
  def initialize
    AWS.config(
      :access_key_id     => APP_CONFIG['S3_KEY'],    # '*** Provide access key ***'
      :secret_access_key => APP_CONFIG['S3_SECRET']  # '*** Provide secret key ***'
    )
  end
  
  def perform(ingest_id, options = {})
    options.symbolize_keys!
    @ingest = Ingest::Audio.find(ingest_id)

    # check what we have to do?
    case @ingest.state
    when :starting
      run_all_stages
    when :resetting, :stopping
      when_liberated do
        @ingest.process!  # => :reset or :stopped
      end
    when :removing
      when_liberated do
        @ingest.process!  # => :removed
      end
    when :restarting
      # wait until current stage is finishing what it is doing
      when_liberated do
        @ingest.process!  # => :starting
        run_all_stages
      end
    end
  rescue Exception => ex
    @ingest.fail! if @ingest
    logger(ex)
    raise ex
  ensure
    liberate!
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
      s3_download_object(APP_CONFIG['S3_OUTBOUND_BUCKET'], s3_key, audio_file_fullpath)
      set_progress! 10
    end
  end
  
  def transcribe!
    stage! :transcribe do
      @ingest.segments.destroy_all
      transcribe_file(audio_file_fullpath)
      cleanup_workspace!
    end
  end
  
  def update_ingestable!
    stage! :update_ingestable do
      content = @ingest.segments.map {|sg| sg.best_text ? sg.best_text.strip : nil}.compact.join(" ")
      @ingest.ingestable.update_attribute(:content, content)
    end
  end

  def remove_upload!
    stage! :remove_upload do
      # Delete uploaded object.
      s3_delete_object(APP_CONFIG['S3_INBOUND_BUCKET'], @ingest.upload.s3_key)
      
      set_progress! 95
    end
  end
  
  def cleanup_workspace!
    File.delete(audio_file_fullpath) if audio_file_fullpath && File.exist?(audio_file_fullpath)
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
      @ingest.update_attributes(stage: stage_name.to_s, busy: true) if @ingest
      yield if block_given?
      @ingest.update_attributes(busy: false) if @ingest
      log! stage_name, header_with("finished", stage_name, message) if block_given?
    end
  end
  
  def can_stage?(stage_name)
    if @ingest
      if @ingest.stage && @ingest.started?
        # get on with the next stage
        return Ingest::AudioWorker::STAGES[stage_name.to_sym] > Ingest::AudioWorker::STAGES[@ingest.stage.to_sym]
      elsif @ingest.stage && @ingest.stage == stage_name.to_s && @ingest.starting?
        # attempt to re-run stage
        @ingest.process!
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
    @ingest.set_progress!(percent) if @ingest
  end

  # set_progress! 10 => 10%
  # increment_progress! 1, 5, 0.8 => 26%
  # increment_progress! 1, 5, 0.8 => 42%
  # ...
  # increment_progress! 1, 5, 0.8 => 90%
  def increment_progress!(counter, denominator, factor = 1.0)
    @ingest.increment_progress!(counter, denominator, factor) if @ingest
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
    log!(@ingest.stage || :errors, errors) if @ingest
    Rails.logger.error errors
  end
  
  def update_s3_url_with(url)
    @ingest.update_attribute :s3_url, url if @ingest
  end
  
  def s3_key
    @ingest.s3_key if @ingest
  end
  
  def s3_url
    @ingest.s3_url if @ingest
  end

  def audio_file
    @ingest.s3_key if @ingest
  end

  def audio_file_fullpath
    File.join("/tmp/" + audio_file) if audio_file
  end
  
  def s3_copy_object(source_bucket_name, destination_bucket_name, source_key, destination_key = nil)
    s3 = AWS::S3.new
    destination_key = source_key if destination_key.blank?
    s3.buckets[source_bucket_name].objects[source_key].copy_to(destination_key, :bucket_name => destination_bucket_name)
  end
  
  def s3_download_object(source_bucket_name, source_key, destination_filename)
    s3 = AWS::S3.new
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
      @ingest.reload
      break unless @ingest.started?
    end
  end
  
  def s3_delete_object(bucket_name, key) 
    s3 = AWS::S3.new
    s3.buckets[bucket_name].objects.delete(key)
  end
  
  def when_liberated
    return unless @ingest
    counter = 0
    while @ingest.busy? && counter < 10
      sleep 1
      @ingest.reload
      counter += 1
    end
    yield unless @ingest.busy?
  end
  
  def liberate!
    @ingest.update_attributes(busy: false) if @ingest 
  end
  
  def run_all_stages
    Ingest::AudioWorker::STAGES.keys.each do |stage|
      send("#{stage}!".to_sym)
    end
  end
end