class Chunk::AttSpeech < Chunk
  class << self
    def engine_class_name; "Speech::Engines::AttSpeechEngine"; end
  end
end
