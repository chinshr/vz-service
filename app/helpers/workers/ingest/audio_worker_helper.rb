module Workers::Ingest::AudioWorkerHelper

  # Transcribe
  def transcribe_file(filename)
    threads = []
    threads << Thread.new { google_speech_transcribe_file(filename) }
    threads << Thread.new { att_speech_transcribe_file(filename) }
    threads << Thread.new { nuance_dragon_transcribe_file(filename) }
    
    threads.each { |thr| thr.join }
    threads
  end
  
  def google_speech_transcribe_file(filename)
    ActiveRecord::Base.connection_pool.with_connection do
      start_time = BigDecimal.new("0.0")
      audio      = Speech::AudioToText.new(filename, {
        engine: :google_speech_engine, chunk_size: @chunk_size, verbose: Rails.env.development?
      })
      audio.to_json(:locale => @ingest.locale) do |chunk|
        end_time = start_time + BigDecimal.new(chunk.duration.to_s)
        @ingest.ingestable.segments.create({
          :type              => "Document::Segment::GoogleSpeech",
          :position          => chunk.id,
          :offset            => chunk.offset,
          :duration          => chunk.duration,
          :start_time        => start_time,
          :end_time          => end_time,
          :text              => chunk.best_text,
          :score             => chunk.best_score,
          :response          => chunk.captured_json,
          :processing_errors => chunk.errors,
          :processing_status => chunk.status
        })
        Rails.logger.info "-> google speech chunk ##{chunk.id}: #{start_time}-#{end_time} (#{chunk.duration}): #{chunk.best_text} (#{chunk.best_score})"

        start_time = end_time
        increment_progress! 1, chunk.splitter.chunks.size, 0.75
        @ingest.reload
        break if !@ingest.started? || @ingest.terminate?
      end
    end
  end

  def att_speech_transcribe_file(filename)
    ActiveRecord::Base.connection_pool.with_connection do
      start_time = BigDecimal.new("0.0")
      audio      = Speech::AudioToText.new(filename, {
        engine: :att_speech_engine, chunk_size: @chunk_size, 
        api_key: "tgcqoeaecj4ff052a9ee8g0mzt9xti7p", secret_key: "j7caqnrtvtiiqhtl1nhlmyp5li0dclxg", 
        mode: "standard", verbose: Rails.env.development?
      })
      audio.to_json(:locale => @ingest.locale) do |chunk|
        end_time = start_time + BigDecimal.new(chunk.duration.to_s)
        @ingest.ingestable.segments.create({
          :type              => "Document::Segment::AttSpeech",
          :position          => chunk.id,
          :offset            => chunk.offset,
          :duration          => chunk.duration,
          :start_time        => start_time,
          :end_time          => end_time,
          :text              => chunk.best_text,
          :score             => chunk.best_score,
          :response          => chunk.captured_json,
          :processing_errors => chunk.errors,
          :processing_status => chunk.status
        })
        Rails.logger.info "-> att speech chunk ##{chunk.id}: #{start_time}-#{end_time} (#{chunk.duration}): #{chunk.best_text} (#{chunk.best_score})"

        start_time = end_time
        increment_progress! 1, chunk.splitter.chunks.size, 0.75
        @ingest.reload
        break if !@ingest.started? || @ingest.terminate?
      end
    end
  end

  def nuance_dragon_transcribe_file(filename)
    ActiveRecord::Base.connection_pool.with_connection do
      start_time = BigDecimal.new("0.0")
      audio      = Speech::AudioToText.new(filename, {
        engine: :nuance_dragon_engine, chunk_size: @chunk_size, 
        base_url: "https://dictation.nuancemobility.net:443", app_id: "NMDPTRIAL_chinshr20140326185635", 
        app_key: "edb1acb2e50d02417b643e6dce510ea9dd565c4ad4725dcb8d807c96fe6304eb14b09ef9bea03a390578a6d3cab57ca70bd8f1df4b4eabd8cf276ecd8a72b99f",
        verbose: Rails.env.development?
      })
      audio.to_json(:locale => @ingest.locale) do |chunk|
        end_time = start_time + BigDecimal.new(chunk.duration.to_s)
        @ingest.ingestable.segments.create({
          :type              => "Document::Segment::NuanceDragon",
          :position          => chunk.id,
          :offset            => chunk.offset,
          :duration          => chunk.duration,
          :start_time        => start_time,
          :end_time          => end_time,
          :text              => chunk.best_text,
          :score             => chunk.best_score,
          :response          => chunk.captured_json,
          :processing_errors => chunk.errors,
          :processing_status => chunk.status
        })
        Rails.logger.info "-> nuance dragon chunk ##{chunk.id}: #{start_time}-#{end_time} (#{chunk.duration}): #{chunk.best_text} (#{chunk.best_score})"

        start_time = end_time
        increment_progress! 1, chunk.splitter.chunks.size, 0.75
        @ingest.reload
        break if !@ingest.started? || @ingest.terminate?
      end
    end
  end
  
  # S3
  
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
  
  def s3_copy_object_if_exists(source_bucket_name, destination_bucket_name, source_key, destination_key = nil)
    s3 = AWS::S3.new
    destination_key = source_key if destination_key.blank?
    if s3.buckets[source_bucket_name].objects[source_key].exists?
      s3.buckets[source_bucket_name].objects[source_key].copy_to(destination_key, :bucket_name => destination_bucket_name)
    end
  end
  
  def s3_delete_object(bucket_name, key) 
    s3 = AWS::S3.new
    s3.buckets[bucket_name].objects.delete(key)
  end

  def s3_delete_object_if_exists(bucket_name, key) 
    s3 = AWS::S3.new
    if bucket_name.present? && key.present? && s3.buckets[bucket_name].objects[key].exists?
      s3.buckets[bucket_name].objects.delete(key)
    end
    true
  rescue AWS::S3::Errors::NoSuchKey => ex
    false
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
  
  # ffmpeg
  
  def ffmpeg_convert_to_mp3(source_file, mp3_file)
    cmd = "ffmpeg -y -i #{source_file} -f mp2 -b #{@mp3_bitrate}k #{mp3_file}   >/dev/null 2>&1"

    Rails.logger.info "-> $ #{cmd}"
    if system(cmd)
      true
    else
      raise "Failed converting audio to mp3 with bitrate #{@mp3_bitrate}k: #{source_file}\n#{cmd}"
    end
  end
  
  def ffmpeg_convert_to_wav_and_strip_audio_channel(input_file, output_file)
    cmd = "ffmpeg -i #{input_file} -y -f wav -ac 1 #{output_file}   >/dev/null 2>&1"

    Rails.logger.info "-> $ #{cmd}"
    if system(cmd)
      true
    else
      raise "Failed convert audio to wav and strip audio channel: #{input_file}\n#{cmd}"
    end
  end
  
  def ffmpeg_downsample_and_convert_to_pcm(input_file, output_file)
    cmd = "ffmpeg -i #{input_file} -ar 16000 -y -f s16le -acodec pcm_s16le #{output_file}"

    Rails.logger.info "-> $ #{cmd}"
    if system(cmd)
      true
    else
      raise "Failed convert audio to pcm and downsample: #{input_file}\n#{cmd}"
    end
  end

  def ffmpeg_convert_pcm_to_wav(input_file, output_file)
    cmd = "ffmpeg -f s16le -ar 16k -ac 1 -y -i #{input_file} #{output_file}"

    Rails.logger.info "-> $ #{cmd}"
    if system(cmd)
      true
    else
      raise "Failed to convert pcm file: #{input_file}\n#{cmd}"
    end
  end

  # SOX
  
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

    Rails.logger.info "-> $ #{cmd}"
    if system(cmd)
      true
    else
      raise "Failed to normalize audio: #{input_file}\n#{cmd}"
    end
  end

  # QIO noise reduction
  
  def qio_silence_flags(input_file, output_file)
    vad_params = if @vad_silence_segments == 25 && @vad_noise_reduce
      "-S 1 -Length 25 \\" +
      "-VADweights #{ENV['AURORACALC']}/parameters/vad/net.tim-fin-tic-it-spn-rand.54i+50h+2o.0-delay-wiener+dct+lpf.wts.head \\" +
      "-VADnorm #{ENV['AURORACALC']}/parameters/vad/tim-fin-tic-it-spn-rand.0-delay-wiener+dct+lpf.norms \\"
    elsif @vad_silence_segments == 20 && !@vad_noise_reduce
      "-S 0 -Length 20 \\" +
      "-VADweights #{ENV['AURORACALC']}/parameters/vad/net.tim-fin-tic-spn-rand.54i+50h+2o.win20-mel-delay+dct+lpf.wts.head \\" +
      "-VADnorm #{ENV['AURORACALC']}/parameters/vad/tim-fin-tic-spn-rand.win20-mel-delay+dct+lpf.norms \\"
    else
      "-S 0 -Length 25 \\" +
      "-VADweights #{ENV['AURORACALC']}/parameters/vad/net.tim-fin-tic-spn-rand.54i+50h+2o.mel-delay+dct+lpf.wts.head \\" +
      "-VADnorm #{ENV['AURORACALC']}/parameters/vad/tim-fin-tic-spn-rand.mel-delay+dct+lpf.norms \\"
    end
    
    cmd = "silence_flags \\" +
      vad_params +
      "-fs 16000 \\" + 
      "-swapin 0 \\" +
      "-i #{input_file} -o #{output_file} "

    Rails.logger.info "-> $ #{cmd}"
    if system(cmd)
      true
    else
      raise "Failed to produce silence file: #{input_file}\n#{cmd}"
    end
  end

  def qio_noise_reduce(input_file, silence_file, output_file)
    length_and_shift = if @vad_silence_segments.modulo(2) == 0
      "-Length #{@vad_silence_segments} -Shift #{@vad_silence_segments / 2} \\"
    else
      "-Length #{@vad_silence_segments} \\"
    end
    
    cmd = "nr -fs 16000 -swapin 0 -swapout 0 \\" +
      length_and_shift +
      "-Ssilfile #{silence_file} \\" +
      "-i #{input_file} -o #{output_file}"

    Rails.logger.info "-> $ #{cmd}"
    if system(cmd)
      true
    else
      raise "Failed to noise reduce file: #{input_file}\n#{cmd}"
    end
  end

  # file management
  
  def delete_file_if_exists(file)
    File.delete(file) if file && File.exist?(file) && !Rails.env.development?
  end
  
  def remove_all_files_and_s3_objects
    # remove local files
    delete_file_if_exists original_audio_file_fullpath
    delete_file_if_exists single_channel_audio_file_fullpath
    delete_file_if_exists normalized_audio_file_fullpath
    delete_file_if_exists mp3_audio_file_fullpath
    delete_file_if_exists pcm_audio_file_fullpath
    delete_file_if_exists silence_file_full_path
    delete_file_if_exists noise_reduced_pcm_audio_file_fullpath

    # remove S3 objects
    s3_delete_object_if_exists(APP_CONFIG['S3_OUTBOUND_BUCKET'], @ingest.track.s3_key)
    s3_delete_object_if_exists(APP_CONFIG['S3_OUTBOUND_BUCKET'], @ingest.track.s3_mp3_key)
  end
  
end