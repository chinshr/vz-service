# -*- encoding: binary -*-
module Speech

  class AudioSplitter
    attr_accessor :original_file, :size, :duration, :chunks, :verbose, :engine

    class AudioChunk
      STATUS_UNPROCESSED         = 0
      STATUS_BUILT               = 1
      STATUS_ENCODED             = 2
      STATUS_TRANSCRIBED         = 3
      STATUS_BUILD_ERROR         = -1
      STATUS_ENCODING_ERROR      = -2
      STATUS_TRANSCRIPTION_ERROR = -3
      
      attr_accessor :id, :splitter, :chunk, :flac_chunk, :wav_chunk, :offset, :duration, :flac_rate, :copied, 
        :captured_json, :best_text, :best_score, :status, :errors

      def initialize(splitter, offset, duration, id = nil)
        self.offset        = offset
        self.chunk         = File.join("/tmp/" + UUID.generate + "-chunk-" + File.basename(splitter.original_file).gsub(/\.(.*)$/, "-#{offset}" + '.\1'))
        self.duration      = duration
        self.id            = id
        self.splitter      = splitter
        self.copied        = false
        self.captured_json = {}
        self.best_text     = nil
        self.best_score    = nil
        self.status        = STATUS_UNPROCESSED
        self.errors        = []
      end

      def engine
        splitter.engine
      end
      
      def self.copy(splitter, id = nil)
        chunk        = AudioChunk.new(splitter, 0, splitter.duration.to_f, id)
        chunk.status = STATUS_BUILT
        chunk.copied = true
        system("cp #{splitter.original_file} #{chunk.chunk}")
        chunk
      end

      # given the original file from the splitter and the chunked file name with duration and offset run the ffmpeg command
      def build
        return self if self.copied
        # ffmpeg -y -i sample.audio.wav -acodec copy -vcodec copy -ss 00:00:00.00 -t 00:00:30.00 sample.audio.out.wav
        offset_ts   = AudioInspector::Duration.from_seconds(self.offset).to_s
        duration_ts = AudioInspector::Duration.from_seconds(self.duration).to_s
        # NOTE: kind of a hack, but if the original source is less than or equal to 1 second, we should skip ffmpeg
        # puts "building chunk: #{duration_ts.inspect} and offset: #{offset_ts}"
        # puts "offset: #{ offset_ts.to_s }, duration: #{duration_ts.to_s}"
        # cmd = "ffmpeg -y -i #{splitter.original_file} -acodec copy -vcodec copy -ss #{offset_ts} -t #{duration_ts} #{self.chunk}   >/dev/null 2>&1"
        # cmd = "ffmpeg -y -i #{splitter.original_file} -acodec copy -vcodec copy -ss #{offset_ts} -t #{duration_ts} -f aiff #{self.chunk}   >/dev/null 2>&1"
        cmd = "ffmpeg -y -i #{splitter.original_file} -acodec flac -vcodec copy -ss #{offset_ts} -t #{duration_ts} -f flac #{self.chunk}   >/dev/null 2>&1"
        if system(cmd)
          self.status = STATUS_BUILT
          self
        else
          self.status = STATUS_BUILD_ERROR
          raise "Failed to generate chunk at offset: #{offset_ts}, duration: #{duration_ts}\n#{cmd}"
        end
      end

      # convert the audio file to flac format
      def to_flac
        chunk_outputfile = chunk.gsub(/#{File.extname(chunk)}$/, ".flac")
        if system("ffmpeg -i #{chunk} -acodec flac #{chunk_outputfile} >/dev/null 2>&1")
          self.flac_chunk = chunk.gsub(/#{File.extname(chunk)}$/, ".flac")
          # convert the audio file to 16K
          self.flac_rate = `ffmpeg -i #{self.flac_chunk} 2>&1`.strip.scan(/Audio: flac, (.*) Hz/).first.first.strip
          down_sampled = self.flac_chunk.gsub(/\.flac$/, '-sampled.flac')
          if system("ffmpeg -i #{self.flac_chunk} -ar 16000 -y #{down_sampled} >/dev/null 2>&1")
            system("mv #{down_sampled} #{self.flac_chunk} 2>&1 >/dev/null")
            self.flac_rate = 16000
            self.status    = STATUS_ENCODED
            self
          else
            self.status    = STATUS_ENCODING_ERROR
            raise "failed to convert to lower audio rate"
          end
        else
          self.status = STATUS_ENCODING_ERROR
          raise "failed to convert chunk: #{chunk} with flac #{chunk}"
        end
        self
      end

      def to_flac_bytes
        File.read(self.flac_chunk)
      end

      def flac_size
        File.size(self.wav_chunk)
      end

      # convert the audio file to wav format
      def to_wav(options = {})
        chunk_outputfile = chunk.gsub(/#{File.extname(chunk)}$/, ".wav")
        if system("ffmpeg -i #{chunk} -y -f wav -ac 1 #{chunk_outputfile}   >/dev/null 2>&1")
          self.wav_chunk = chunk.gsub(/#{File.extname(chunk)}$/, ".wav")
          # convert the audio file to 16K
          # self.flac_rate = `ffmpeg -i #{self.wav_chunk} 2>&1`.strip.scan(/Audio: wav, (.*) Hz/).first.first.strip
          down_sampled = self.wav_chunk.gsub(/\.wav$/, '-sampled.wav')
          if system("ffmpeg -i #{self.wav_chunk} -ar 16000 -y #{down_sampled} >/dev/null 2>&1")
            system("mv #{down_sampled} #{self.wav_chunk} 2>&1 >/dev/null")
            self.flac_rate = 16000
            self.status    = STATUS_ENCODED
          else
            self.status    = STATUS_ENCODING_ERROR
            raise "failed to convert to lower audio rate"
          end
        else
          self.status = STATUS_ENCODING_ERROR
          raise "failed to convert chunk: #{chunk} with wav #{chunk}"
        end
        self
      end

      def to_wav_bytes
        File.read(self.wav_chunk)
      end

      def wav_size
        File.size(self.wav_chunk)
      end

      # delete the chunk file
      def clean
        File.unlink self.chunk if File.exist?(self.chunk)
        File.unlink self.flac_chunk if self.flac_chunk && File.exist?(self.flac_chunk)
        File.unlink self.wav_chunk if self.wav_chunk && File.exist?(self.wav_chunk)
      end
    end # AudioChunk

    def initialize(file, options = {})
      self.original_file = file      
      self.duration      = AudioInspector.new(file).duration
      self.size          = options.key?(:chunk_size) ? options[:chunk_size].to_i : 5
      self.chunks        = []
      self.verbose       = !!options[:verbose] if options.key?(:verbose)
      self.engine        = options[:engine]
    end

    def split
      # compute the total number of chunks
      chunk_id    = 1
      full_chunks = (self.duration.to_f / size).to_i
      last_chunk  = ((self.duration.to_f % size) * 100).round / 100.0
      puts "generate: #{full_chunks} chunks of #{size} seconds, last: #{last_chunk} seconds" if self.verbose

      (full_chunks - 1).times do |index|
        if index > 0
          chunks << AudioChunk.new(self, index * self.size, self.size, chunk_id)
        else
          off = (index * self.size) - (self.size / 2)
          off = 0 if off < 0
          chunks << AudioChunk.new(self, off, self.size, chunk_id)
        end
        chunk_id += 1
      end

      if chunks.empty?
        chunks << AudioChunk.copy(self, chunk_id)
      else
        chunks << AudioChunk.new(self, chunks.last.offset.to_i + chunks.last.duration.to_i, self.size + last_chunk, chunk_id)
      end
      puts "Chunk (id=#{chunk_id}) count: #{chunks.size}" if self.verbose
      chunks
    end

  end
end
