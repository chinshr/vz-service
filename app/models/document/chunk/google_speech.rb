class Document::Chunk::GoogleSpeech < Document::Chunk
  class << self
    def engine_class_name; "Speech::Engines::GoogleSpeechEngine"; end
  end
end
