class Chunk::PocketsphinxChunk < ::Chunk
  class << self
    def engine_class_name; "Speech::Engines::PocketsphinxEngine"; end
  end
end