# -*- encoding: binary -*-
module Speech
  module Engines
    class NuanceDragonEngine < Base
      attr_accessor :http, :uri, :base_url, :app_id, :app_key, :device_id
      
      def initialize(file, options = {})
        super file, options
        
        self.base_url  = options.key?(:base_url) ? options[:base_url] : "http://sandbox.nmdp.nuancemobility.net"
        self.app_id    = options[:app_id] if options.key?(:app_id)
        self.app_key   = options[:app_key] if options.key?(:app_key)
        self.device_id = options.key?(:device_id) ? options[:device_id] : "8CGoCMXyIcJosb2"
      end
      
      protected
      
      def reset!(options = {})
        super options
        url       = "#{base_url}/NMDPAsrCmdServlet/dictation?appId=#{app_id}&appKey=#{app_key}&id=#{device_id}"
        self.uri  = URI.parse(url)
        self.http = Net::HTTP.new(uri.host, uri.port)
        if uri.scheme == "https"
          http.use_ssl     = true
          # http.verify_mode = OpenSSL::SSL::VERIFY_NONE
          http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        else
          http.use_ssl = false
        end
      end
      
      def build(chunk)
        chunk.build.to_pcm
      end
      
      def convert_chunk(chunk, options = {})
        puts "sending chunk of size #{chunk.duration}, locale: #{locale}..." if self.verbose
        retrying    = true
        retry_count = 0
        headers     = {}
        result      = {'status' => STATUS_UNPROCESSED}

        while retrying && retry_count < 3 # 3 retries
          # service.verbose = self.verbose
          
          # headers
          headers['Content-Type']                = "audio/x-wav;codec=pcm;bit=16;rate=#{chunk.flac_rate}"
          headers['Accept-Topic']                = "Dictation" # Dictation or WebSearch
          if options.key?(:audio_source)
            headers['X-Dictation-NBestListSize'] = max_results.to_s
            headers['X-Dictation-AudioSource']   = "" # SpeakerAndMicrophone, HeadsetInOut, HeadsetBT, HeadPhone, LineOut
          end
          # headers['Content-Length']              = chunk.to_pcm_bytes.size.to_s  # chunk.wav_size.to_s  # if not, headers['Transfer-Encoding'] = "chunked"
          headers['Transfer-Encoding'] = "chunked"
          headers['Content-Language']            = normalize_language(locale)
          headers['Accept-Language']             = normalize_language(locale)
          headers['Accept']                      = "application/plain" # application/xml or text/plain
          headers['Expect']                      = ""
          
          Net::HTTP.http_logger_options = {:trace => true, :body => true, :header => true, :verbose => true} if verbose
          
          # request
          request              = Net::HTTP::Post.new(uri.path + "?" + uri.query, headers)
          request.content_type = headers["Content-Type"]
          request.body         = chunk.to_pcm_bytes  # chunk.to_wav_binary.unpack("B*")[0]
          response             = http.request(request)

          # response.is_a?(Net::HTTPSuccess) 
          if service.response_code >= 500
            puts "500 from Nuance retry after 0.5 seconds" if self.verbose
            retrying    = true
            retry_count += 1
            sleep 0.5 # wait longer on error?, google??
          else
            # {"status":0,"id":"ce178ea89f8b17d8e8298c9c7814700a-1","hypotheses":[{"utterance"=>"I like pickles", "confidence"=>0.59408695}, {"utterance"=>"I like turtles"}, {"utterance"=>"I like tickles"}, {"utterance"=>"I like to Kohl's"}, {"utterance"=>"I Like tickles"}, {"utterance"=>"I lyk tickles"}, {"utterance"=>"I liked to Kohl's"}]}
            debugger
            data                 = JSON.parse(service.body_str)
            result['status']     = STATUS_PROCESSED # data['status']
            result['id']         = data['id']
            # result['hypotheses'] = data['hypotheses'].map {|ut| [ut['utterance'], ut['confidence']]}
            result['hypotheses'] = data['hypotheses'].map {|ut| {'hypothesis' => ut['utterance'], 'confidence' => ut['confidence']}}

            if data.key?('hypotheses') && data['hypotheses'].first
              chunk.best_text  = data['hypotheses'].first['utterance']
              chunk.best_score = data['hypotheses'].first['confidence']
              self.score       += data['hypotheses'].first['confidence']
              self.segments    += 1
              puts data['hypotheses'].first['utterance'] if self.verbose
            end
            retrying = false
          end

          sleep 0.1 # not too fast there tiger
        end

        puts "#{segments} processed: #{result.inspect} from: #{data.inspect}" if self.verbose
      # rescue Exception => ex
      #   result['status'] = STATUS_ERROR
      #   result['errors'] = [ex.message]
      #   raise ex
      # ensure
      #   chunk.clean
      #   chunk.captured_json = result
      #   return result
      end
      
      private
      
      def normalize_language(locale)
        locale.gsub("-", "_").downcase if locale
      end
    end
  end
end