require 'test_helper'

class Chunk::SubtitleChunkTest < ActiveSupport::TestCase

  should "#engine_class_name" do
    assert_equal "Speech::Engines::SubtitleEngine", Chunk::SubtitleChunk.engine_class_name
  end

end
