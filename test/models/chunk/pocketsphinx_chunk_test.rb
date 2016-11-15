require 'test_helper'

class Chunk::PocketsphinxChunkTest < ActiveSupport::TestCase

  should "#engine_class_name" do
    assert_equal "Speech::Engines::PocketsphinxEngine", Chunk::PocketsphinxChunk.engine_class_name
  end

end
