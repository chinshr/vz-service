# -*- encoding: binary -*-
module Speech
  module Engines
    class GoogleSpeechEngine < Base
      attr_accessor :service
      
      protected
      
      def reset!(options = {})
        super options
        
        url          = "https://www.google.com/speech-api/v1/recognize?xjerr=1&client=speech2text&lang=#{locale}&maxresults=#{max_results}"
        self.service = Curl::Easy.new(url)
      end
      
      def build(chunk)
        chunk.build.to_flac
      end
      
      def convert_chunk(chunk, options = {})
        puts "sending chunk of size #{chunk.duration}, locale: #{locale}..." if self.verbose
        retrying    = true
        retry_count = 0
        result      = {'status' => STATUS_UNPROCESSED}

        while retrying && retry_count < 3 # 3 retries
          service.verbose = self.verbose

          # headers
          service.headers['Content-Type'] = "audio/x-flac; rate=#{chunk.flac_rate}"
          service.headers['User-Agent']   = USER_AGENT
          
          # request
          service.post_body = "Content=#{chunk.to_flac_bytes}"
          service.on_progress {|dl_total, dl_now, ul_total, ul_now| printf("%.2f/%.2f\r", ul_now, ul_total); true} if self.verbose
          service.http_post
          
          if service.response_code == 500
            puts "500 from google retry after 0.5 seconds" if self.verbose
            retrying    = true
            retry_count += 1
            sleep 0.5 # wait longer on error?, google??
          else
            # {"status":0,"id":"ce178ea89f8b17d8e8298c9c7814700a-1","hypotheses":[{"utterance"=>"I like pickles", "confidence"=>0.59408695}, {"utterance"=>"I like turtles"}, {"utterance"=>"I like tickles"}, {"utterance"=>"I like to Kohl's"}, {"utterance"=>"I Like tickles"}, {"utterance"=>"I lyk tickles"}, {"utterance"=>"I liked to Kohl's"}]}
            data                      = JSON.parse(service.body_str)
            result['id']              = chunk.id
            result['external_id']     = data['id']
            result['external_status'] = data['status']
            result['hypotheses']      = data['hypotheses'].map {|ut| {'utterance' => ut['utterance'], 'confidence' => ut['confidence']}}

            if data.key?('hypotheses') && data['hypotheses'].first
              result['status'] = STATUS_PROCESSED
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
      rescue Exception => ex
        result['status'] = STATUS_ERROR
        result['errors'] = [ex.message.to_s.gsub(/\n|\r/, "")]
      ensure
        chunk.clean
        chunk.captured_json = result
        return result
      end
      
      private
      
      def supported_locales
        ["af", "eu", "bg", "ca", "ar-EG", "ar-JO", "ar-KW", "ar-LB", "ar-QA", "ar-AE", "ar-MA", "ar-IQ", "ar-DZ", "ar-BH", "ar-LY",
         "ar-OM", "ar-SA", "ar-TN", "ar-YE", "cs", "nl-NL", "en-AU", "en-CA", "en-IN", "en-NZ", "en-ZA", "en-GB", "en-US", "fi", 
         "fr-FR", "gl", "de-DE", "he", "hu", "is", "it-IT", "id", "ja", "ko", "la", "zh-CN", "zh-TW", "zh-HK", "zh-yue", "ms-MY", 
         "no-NO", "pl", "pt-PT", "pt-BR", "ro-RO", "ru", "sr-SP", "sk", "es-AR", "es-BO", "es-CL", "es-CO", "es-CR", "es-DO", 
         "es-EC", "es-SV", "es-GT", "es-HN", "es-MX", "es-NI", "es-PA", "es-PY", "es-PE", "es-PR", "es-ES", "es-US", "es-UY", 
         "es-VE", "sv-SE", "tr", "zu"]
      end
    end
  end
end