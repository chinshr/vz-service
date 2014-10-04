class Document::Chunk::NuanceDragon < Document::Chunk
  class << self
    def engine_class_name; "Speech::Engines::NuanceDragonEngine"; end
  end
end
