class Chunk::GoogleSpeech < Chunk
  class << self
    def engine_class_name; "Speech::Engines::GoogleSpeechEngine"; end
  end
end
