# -*- encoding: binary -*-
module Speech
  class AudioToText
    attr_accessor :engine

    def initialize(file, options = {})
      engine_class = options.key?(:engine) ? "Speech::Engines::#{options[:engine].to_s.classify}".constantize : Engines::GoogleSpeechEngine
      self.engine  = engine_class.new(file, options)
    end

    def to_text(options = {})
      engine.to_text(options)
    end

    def to_json(options = {})
      engine.to_json(options)
    end
  end
end
