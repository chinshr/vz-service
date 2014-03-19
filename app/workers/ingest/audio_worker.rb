require 'rubygems'
require 'aws-sdk'
require "speech"

class Ingest::AudioWorker
  include Sidekiq::Worker
  sidekiq_options :queue => :default, :retry => false, :backtrace => true

  STAGES = {
    :initialize_pipeline                         => 0,
    :move_object_from_inbound_to_outbound_bucket => 1,
    :download_object_from_outbound_bucket        => 2,
    :normalize_original_audio_file               => 3,
    :create_mp3_and_upload                       => 4,
    :transcribe                                  => 5,
    :update_ingestable                           => 6,
    :finalized                                   => 7
  }
  
  def initialize(ingest_id = nil)
    AWS.config(
      :access_key_id     => APP_CONFIG['S3_KEY'],    # '*** Provide access key ***'
      :secret_access_key => APP_CONFIG['S3_SECRET']  # '*** Provide secret key ***'
    )
    
    # For server debugging purposes
    @ingest = Ingest::Audio.find(ingest_id) if ingest_id
    
    @mp3_bitrate = 128
  end
  
  def perform(ingest_id, options = {})
    options.symbolize_keys!
    @ingest = Ingest::Audio.find(ingest_id)

    # check what we have to do?
    case @ingest.state
    when :starting
      puts "--> processing #{@ingest.state}"
      @ingest.process!
      run_all_stages
    when :resetting, :stopping
      puts "--> waiting liberation #{@ingest.state}"
      when_liberated do
        puts "--> processing #{@ingest.state}"
        @ingest.process!  # => :reset or :stopped
      end
    when :removing
      puts "--> waiting liberation #{@ingest.state}"
      when_liberated do
        puts "--> processing #{@ingest.state}"
        remove_all_files_and_s3_objects
        @ingest.process!  # => :removed
      end
    when :restarting
      # wait until current stage is finishing what it is doing
      puts "--> waiting liberation #{@ingest.state}"
      when_liberated do
        puts "--> processing #{@ingest.state}"
        @ingest.clear_terminate!
        @ingest.process!
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

  def initialize_pipeline!
    stage! :initialize_pipeline do
      @ingest.track.destroy if @ingest.track
      @ingest.create_track(:s3_url => "initializing")
      @ingest.save if @ingest.changed?
      set_progress! 0
    end
  end

  def move_object_from_inbound_to_outbound_bucket!
    stage! :move_object_from_inbound_to_outbound_bucket, "object key #{@ingest.upload.s3_key}" do
      # Copy the object to outbound folder.
      s3_copy_object_if_exists APP_CONFIG['S3_INBOUND_BUCKET'], APP_CONFIG['S3_OUTBOUND_BUCKET'], @ingest.upload.s3_key

      # Update s3 references
      @ingest.track.update_attribute(:s3_url, outbound_url(@ingest.upload.s3_key))

      # Delete uploaded object
      s3_delete_object_if_exists(APP_CONFIG['S3_INBOUND_BUCKET'], @ingest.upload.s3_key)
      
      set_progress! 5
    end
  end

  def download_object_from_outbound_bucket!
    stage! :download_object_from_outbound_bucket do
      s3_download_object APP_CONFIG['S3_OUTBOUND_BUCKET'], @ingest.track.s3_key, original_audio_file_fullpath
      set_progress! 10
    end
  end

  def normalize_original_audio_file!
    stage! :normalize_original_audio_file do
      # Create single WAV file
      puts "--> before ffmpeg_convert_to_wav_and_strip_audio_channel"
      ffmpeg_convert_to_wav_and_strip_audio_channel original_audio_file_fullpath, single_channel_audio_file_fullpath

      puts "--> before sox_normalize_audio"
      # Noise cancel and normalize it
      delete_file_if_exists normalized_audio_file_fullpath
      sox_normalize_audio single_channel_audio_file_fullpath, normalized_audio_file_fullpath
      
      # Delete the single channel file
      puts "--> delete single_channel_audio_file_fullpath"
      delete_file_if_exists single_channel_audio_file_fullpath
      
      set_progress! 20
    end
  end
  
  def create_mp3_and_upload!
    stage! :create_mp3_and_upload do
      # Convert to mp3
      ffmpeg_convert_to_mp3 normalized_audio_file_fullpath, mp3_audio_file_fullpath
      
      # Upload mp3
      s3_upload_object(mp3_audio_file_fullpath, APP_CONFIG['S3_OUTBOUND_BUCKET'], mp3_audio_file)
      
      # Update s3 references
      @ingest.track.update_attribute(:s3_mp3_url, outbound_url(mp3_audio_file))
      
      # Remove mp3 file locally
      delete_file_if_exists mp3_audio_file_fullpath
      
      set_progress! 15
    end
  end

  def transcribe!
    stage! :transcribe do
      # Remove previous segments (in case we reprocessing)
      @ingest.ingestable.segments.destroy_all
      
      # Start the stranscription with normalization
      transcribe_file(normalized_audio_file_fullpath)
      
      # Sweep files we don't need anymore
      delete_file_if_exists normalized_audio_file_fullpath
      delete_file_if_exists original_audio_file_fullpath
    end
  end
  
  def update_ingestable!
    stage! :update_ingestable do
      content = @ingest.ingestable.segments.map {|sg| sg.text ? sg.text.strip : nil}.compact.join(" ")
      @ingest.ingestable.update_attribute(:content, content)
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
      @ingest.update_attributes(stage: stage_name.to_s, busy: true) if @ingest
      yield if block_given?
      @ingest.update_attributes(busy: false) if @ingest
      log! stage_name, header_with("finished", stage_name, message) if block_given?
    end
  end
  
  def can_stage?(stage_name)
    if @ingest && !@ingest.terminate?
      if @ingest.stage && @ingest.started?
        # get on with the next stage
        return Ingest::AudioWorker::STAGES[stage_name.to_sym] > Ingest::AudioWorker::STAGES[@ingest.stage.to_sym]
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
    puts "** stage #{stage_name}: #{message}" if @ingest && Rails.env.development?
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
  
  def s3_key
    @ingest.s3_key if @ingest
  end
  
  def s3_url
    @ingest.track.s3_url if @ingest
  end

  def original_audio_file
    @ingest.track.s3_key if @ingest
  end

  def original_audio_file_fullpath
    File.join("/tmp", original_audio_file) if original_audio_file
  end

  def mp3_audio_file
    "#{@ingest.track.s3_key}.#{@mp3_bitrate}.mp3" if @ingest
  end

  def mp3_audio_file_fullpath
    File.join("/tmp", mp3_audio_file) if mp3_audio_file
  end

  def single_channel_audio_file
    "#{@ingest.track.s3_key}.single-channel" if @ingest
  end
  
  def single_channel_audio_file_fullpath
    File.join("/tmp", single_channel_audio_file) if single_channel_audio_file
  end

  def normalized_audio_file
    "#{@ingest.track.s3_key}.normalized.wav" if @ingest
  end

  def normalized_audio_file_fullpath
    File.join("/tmp", normalized_audio_file) if normalized_audio_file
  end
  
  def outbound_url(key)
    File.join(APP_CONFIG['S3_URL'], APP_CONFIG['S3_OUTBOUND_BUCKET'], key)
  end

  def inbound_url(key)
    File.join(APP_CONFIG['S3_URL'], APP_CONFIG['S3_INBOUND_BUCKET'], key)
  end
  
  def s3_copy_object_if_exists(source_bucket_name, destination_bucket_name, source_key, destination_key = nil)
    s3 = AWS::S3.new
    destination_key = source_key if destination_key.blank?
    if s3.buckets[source_bucket_name].objects[source_key].exists?
      s3.buckets[source_bucket_name].objects[source_key].copy_to(destination_key, :bucket_name => destination_bucket_name)
    end
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
      @ingest.ingestable.segments.create(
        :offset      => chunk.offset,
        :duration    => chunk.duration,
        :start_time  => start_time,
        :end_time    => end_time,
        :text        => chunk.best_text,
        :score       => chunk.best_score,
        :response    => chunk.captured_json
      )
      start_time = end_time
      increment_progress! 1, chunk.splitter.chunks.size, 0.8
      @ingest.reload
      break if !@ingest.started? || @ingest.terminate?
    end
  end
  
  def s3_delete_object(bucket_name, key) 
    s3 = AWS::S3.new
    s3.buckets[bucket_name].objects.delete(key)
  end

  def s3_delete_object_if_exists(bucket_name, key) 
    s3 = AWS::S3.new
    if s3.buckets[bucket_name].objects[key].exists?
      s3.buckets[bucket_name].objects.delete(key)
    end
  end
  
  def when_liberated
    return unless @ingest
    counter = 0
    @ingest.reload
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
  
  def ffmpeg_convert_to_mp3(source_file, mp3_file)
    cmd = "ffmpeg -y -i #{source_file} -f mp2 -b #{@mp3_bitrate}k #{mp3_file}   >/dev/null 2>&1"
    if system(cmd)
      true
    else
      raise "Failed converting audio to mp3 with bitrate #{@mp3_bitrate}k: #{source_file}\n#{cmd}"
    end
  end
  
  def s3_upload_object(local_file, bucket_name, key = nil)
    s3 = AWS::S3.new
    AWS.config.http_handler.pool.empty!
    
    key = File.basename(local_file) unless key
    Rails.logger.info "-->> start s3 upload: #{local_file}, #{bucket_name}, #{key}"
    if false
      s3.buckets[bucket_name].objects[key].write(:file => local_file)
    else
      s3.buckets[bucket_name].objects[key].write(File.open(local_file), content_length: File.size(local_file))
    end
    Rails.logger.info "-->> finished s3 upload: #{local_file}, #{bucket_name}, #{key}"
  end

  def ffmpeg_convert_to_wav_and_strip_audio_channel(input_file, output_file)
    cmd = "ffmpeg -i #{input_file} -y -f wav -ac 1 #{output_file}   >/dev/null 2>&1"
    if system(cmd)
      true
    else
      raise "Failed convert audio to wav and strip audio channel: #{input_file}\n#{cmd}"
    end
  end
    
  def sox_normalize_audio(input_file, output_file)
    cmd = "sox #{input_file} #{output_file} \\" +
      "remix - \\" +
      "highpass 100 \\" +
      "norm \\" +
      "compand 0.05,0.2 6:-54,-90,-36,-36,-24,-24,0,-12 0 -90 0.1 \\" + 
      "vad -T 0.6 -p 0.2 -t 5 \\" +
      "fade 0.1 \\" +
      "reverse \\" +
      "vad -T 0.6 -p 0.2 -t 5 \\" +
      "fade 0.1 \\" +
      "reverse \\" +
      "norm -0.5"
    if system(cmd)
      true
    else
      raise "Failed to normalize audio: #{input_file}\n#{cmd}"
    end
  end

  def delete_file_if_exists(file)
    File.delete(file) if file && File.exist?(file)
  end
  
  def remove_all_files_and_s3_objects
    # remove local files
    delete_file_if_exists original_audio_file_fullpath
    delete_file_if_exists single_channel_audio_file_fullpath
    delete_file_if_exists normalized_audio_file_fullpath
    delete_file_if_exists mp3_audio_file_fullpath

    # remove S3 objects
    s3_delete_object_if_exists(APP_CONFIG['S3_OUTBOUND_BUCKET'], @ingest.track.s3_key)
    s3_delete_object_if_exists(APP_CONFIG['S3_OUTBOUND_BUCKET'], @ingest.track.s3_mp3_key)
  end
  
end