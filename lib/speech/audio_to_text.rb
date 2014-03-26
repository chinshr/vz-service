# -*- encoding: binary -*-
module Speech
  class AudioToText
    attr_accessor :engine

    def initialize(file, options = {})
      engine_class = options.key?(:engine) ? "Speech::Engines::#{options[:engine].to_s.classify}".constantize : Engines::GoogleSpeechEngine
      self.engine  = engine_class.new(file, options)
    end

    def to_text(max = 2, lang = "en-US")
      engine.to_text(max, lang)
    end

    def to_json(max = 2, lang = "en-US")
      engine.to_json(max, lang)
    end
  end
end
