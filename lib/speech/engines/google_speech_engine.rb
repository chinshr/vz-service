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
          service.headers['Content-Type'] = "audio/x-flac; rate=#{chunk.flac_rate}"
          # service.headers['User-Agent'] = "https://github.com/taf2/speech2text"
          service.headers['User-Agent'] = "Mozilla/5.0"
          service.post_body = "Content=#{chunk.to_flac_bytes}"
          if self.verbose
            service.on_progress {|dl_total, dl_now, ul_total, ul_now| printf("%.2f/%.2f\r", ul_now, ul_total); true }
          end
          service.http_post
          if service.response_code == 500
            puts "500 from google retry after 0.5 seconds" if self.verbose
            retrying    = true
            retry_count += 1
            sleep 0.5 # wait longer on error?, google??
          else
            # {"status":0,"id":"ce178ea89f8b17d8e8298c9c7814700a-1","hypotheses":[{"utterance"=>"I like pickles", "confidence"=>0.59408695}, {"utterance"=>"I like turtles"}, {"utterance"=>"I like tickles"}, {"utterance"=>"I like to Kohl's"}, {"utterance"=>"I Like tickles"}, {"utterance"=>"I lyk tickles"}, {"utterance"=>"I liked to Kohl's"}]}
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
      rescue Exception => ex
        result['status'] = STATUS_ERROR
        result['errors'] = [ex.message]
      ensure
        chunk.clean
        chunk.captured_json = result
        return result
      end
    end
  end
end