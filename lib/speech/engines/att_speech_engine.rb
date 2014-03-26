# -*- encoding: binary -*-
module Speech
  module Engines
    class AttSpeechEngine < Base
      include ::Att::Codekit
      
      SCOPE = "SPEECH"  # "STTC"
      
      attr_accessor :api_key, :secret_key, :oauth, :token, :service

      def initialize(file, options = {})
        super(file, options)
        
        self.api_key       = options[:api_key] if options.key?(:api_key)
        self.secret_key    = options[:secret_key] if options.key?(:secret_key)
        self.oauth         = Auth::ClientCred.new("https://api.att.com", api_key, secret_key)
        self.token         = oauth.createToken(SCOPE)
        self.service       = Service::SpeechService.new("https://api.att.com", token)
      end
      
      protected
      
      def build(chunk)
        chunk.build.to_wav
      end
      
      def convert_chunk(chunk, options = {})
        puts "sending chunk of size #{chunk.duration}..." if self.verbose
        retrying    = true
        retry_count = 0
        result      = {}
      
        while retrying && retry_count < 3 # 3 retries
          response = service.speechToText(chunk.wav_chunk, {})
          
          if response.status != "OK"
            puts "'Speech Not Recognized' from ATT retry after 0.5 seconds" if self.verbose
            retrying    = true
            retry_count += 1
            sleep 0.5
          else
            data                              = JSON.parse(response.nbest.to_json)
            chunk.captured_json['status']     = "#{response.status}"
            chunk.captured_json['id']         = "#{response.id}"
            chunk.captured_json['hypotheses'] = data.map {|ut| {'hypothesis' => ut['hypothesis'], 'confidence' => ut['confidence'], 'language' => ut['language']}}
          
            if data.first
              chunk.best_text  = data.first['result']
              chunk.best_score = data.first['confidence']
              self.score       += data.first['confidence']
              self.segments    += 1
              puts data.first['result'] if self.verbose
            end
            retrying = false
          end
        
          sleep 0.1 # not too fast there tiger
        end
      
        puts "#{segments} processed: #{self.captured_json.inspect}" if self.verbose
      ensure
        chunk.clean
        return result
      end
    end
  end
end