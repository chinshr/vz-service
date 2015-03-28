class Ingest::Chunk::NuanceDragon < Ingest::Chunk
  class << self
    def engine_class_name; "Speech::Engines::NuanceDragonEngine"; end
  end
end
