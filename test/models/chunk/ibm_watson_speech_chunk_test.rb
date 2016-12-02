require 'test_helper'

class Chunk::IbmWatsonSpeechChunkTest < ActiveSupport::TestCase

  should "#engine_class_name" do
    assert_equal "Speech::Engines::IbmWatsonSpeechEngine", Chunk::IbmWatsonSpeechChunk.engine_class_name
  end

end
