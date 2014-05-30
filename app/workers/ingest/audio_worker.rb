require "rubygems"
require "aws-sdk"
require "speech"

class Ingest::AudioWorker
  include Sidekiq::Worker
  include Workers::Ingest::AudioWorkerHelper
  
  sidekiq_options :queue => :default, :retry => false, :backtrace => true

  STAGES = {
    :initialize_pipeline                         => 0,
    :move_object_from_inbound_to_outbound_bucket => 10,
    :download_object_from_outbound_bucket        => 20,
    :normalize_original_audio_file               => 30,
    :noise_reduce_audio_file                     => 35, 
    :create_mp3_and_upload                       => 40,
    :transcribe                                  => 50,
    :finalized                                   => 60
  }
  
  def initialize(ingest_id = nil)
    AWS.config(
      :access_key_id     => APP_CONFIG['S3_KEY'],    # '*** Provide access key ***'
      :secret_access_key => APP_CONFIG['S3_SECRET']  # '*** Provide secret key ***'
    )
    
    # For server debugging purposes
    @ingest               = Ingest::Audio.find(ingest_id) if ingest_id
    @mp3_bitrate          = 128    # in kbits
    @chunk_size           = 10     # in seconds
    @vad_silence_segments = 20     # in ms
    @vad_noise_reduce     = false  # noise reduce, true or false (note: true only works with 25ms silence segments)
  end
  
  def perform(ingest_id, options = {})
    options.symbolize_keys!
    @ingest = Ingest::Audio.find(ingest_id)

    # check what we have to do?
    case @ingest.state
    when :starting
      Rails.logger.info "--> processing #{@ingest.state}"
      @ingest.process!
      run_all_stages
    when :resetting, :stopping
      Rails.logger.info "--> waiting liberation #{@ingest.state}"
      when_liberated do
        Rails.logger.info "--> processing #{@ingest.state}"
        @ingest.process!  # => :reset or :stopped
      end
    when :removing
      Rails.logger.info "--> waiting liberation #{@ingest.state}"
      when_liberated do
        Rails.logger.info "--> processing #{@ingest.state}"
        remove_all_files_and_s3_objects
        @ingest.process!  # => :removed
      end
    when :restarting
      # wait until current stage is finishing what it is currently doing!
      Rails.logger.info "--> waiting liberation #{@ingest.state}"
      when_liberated do
        Rails.logger.info "--> processing #{@ingest.state}"
        @ingest.clear_terminate!
        @ingest.process!
        run_all_stages
      end
    end
  rescue Exception => ex
    @ingest.fail! if @ingest
    exception_logger(ex)
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
      Rails.logger.info "--> before ffmpeg_convert_to_wav_and_strip_audio_channel"
      ffmpeg_convert_to_wav_and_strip_audio_channel original_audio_file_fullpath, single_channel_audio_file_fullpath

      Rails.logger.info "--> before sox_normalize_audio"
      # Noise cancel and normalize it
      sox_normalize_audio single_channel_audio_file_fullpath, normalized_audio_file_fullpath
      
      # Delete the single channel file
      Rails.logger.info "--> delete single_channel_audio_file_fullpath"
      delete_file_if_exists single_channel_audio_file_fullpath
      
      set_progress! 15
    end
  end

  def noise_reduce_audio_file!
    stage! :noise_reduce_audio_file do
      # Convert to raw headerless PCM and down sample to 16-bit
      ffmpeg_downsample_and_convert_to_pcm(normalized_audio_file_fullpath, pcm_audio_file_fullpath)
      
      # Figure out none speech sections
      qio_silence_flags(pcm_audio_file_fullpath, silence_file_full_path)
      
      # Apply the QIO NR with silence file
      qio_noise_reduce(pcm_audio_file_fullpath, silence_file_full_path, noise_reduced_pcm_audio_file_fullpath)
      
      # Convert PCM back to WAV
      ffmpeg_convert_pcm_to_wav(noise_reduced_pcm_audio_file_fullpath, noise_reduced_wav_audio_file_fullpath)

      # Delete no more used files
      delete_file_if_exists pcm_audio_file_fullpath
      delete_file_if_exists silence_file_full_path
      delete_file_if_exists noise_reduced_pcm_audio_file_fullpath
      
      set_progress! 20
    end
  end
  
  def create_mp3_and_upload!
    stage! :create_mp3_and_upload do
      # Convert to mp3
      ffmpeg_convert_to_mp3 noise_reduced_wav_audio_file_fullpath, mp3_audio_file_fullpath
      
      # Upload mp3
      s3_upload_object(mp3_audio_file_fullpath, APP_CONFIG['S3_OUTBOUND_BUCKET'], mp3_audio_file)
      
      # Update s3 references
      @ingest.track.update_attribute(:s3_mp3_url, outbound_url(mp3_audio_file))
      
      # Remove mp3 file locally
      delete_file_if_exists mp3_audio_file_fullpath
      
      set_progress! 25
    end
  end

  def transcribe!
    stage! :transcribe do
      # Remove previous chunks (in case we reprocessing)
      @ingest.ingestable.chunks.destroy_all
      
      # Start the stranscription with normalization
      transcribe_file(noise_reduced_wav_audio_file_fullpath)
      
      # Normalize chunk scores
      normalize_document_chunk_scores(@ingest.ingestable.chunks)
      
      # Update document
      content = @ingest.ingestable.chunks.map {|sg| sg.text ? sg.text.strip : nil}.compact.join(" ")
      @ingest.ingestable.update_attribute(:content, content)
      
      # Sweep files we don't need anymore
      delete_file_if_exists normalized_audio_file_fullpath
      delete_file_if_exists original_audio_file_fullpath
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
    Rails.logger.info "** stage #{stage_name}: #{message}" if @ingest && Rails.env.development?
    @ingest.log! stage_name, message if @ingest
  end
  
  def exception_logger(exception)
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
  
  def pcm_audio_file
    "#{@ingest.track.s3_key}.pcm" if @ingest
  end
  
  def pcm_audio_file_fullpath
    File.join("/tmp", pcm_audio_file) if pcm_audio_file
  end

  def silence_file
    "#{@ingest.track.s3_key}.s" if @ingest
  end
  
  def silence_file_full_path
    File.join("/tmp", silence_file) if silence_file
  end

  def noise_reduced_pcm_audio_file
    "#{@ingest.track.s3_key}.nr.pcm" if @ingest
  end

  def noise_reduced_pcm_audio_file_fullpath
    File.join("/tmp", noise_reduced_pcm_audio_file) if noise_reduced_pcm_audio_file
  end
  
  def noise_reduced_wav_audio_file
    "#{@ingest.track.s3_key}.nr.wav" if @ingest
  end

  def noise_reduced_wav_audio_file_fullpath
    File.join("/tmp", noise_reduced_wav_audio_file) if noise_reduced_wav_audio_file
  end
  
  def outbound_url(key)
    File.join(APP_CONFIG['S3_URL'], APP_CONFIG['S3_OUTBOUND_BUCKET'], key)
  end

  def inbound_url(key)
    File.join(APP_CONFIG['S3_URL'], APP_CONFIG['S3_INBOUND_BUCKET'], key)
  end
  
  def when_liberated
    return unless @ingest
    counter = 0
    @ingest.reload
    while @ingest.busy? && counter < @chunk_size * 2
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