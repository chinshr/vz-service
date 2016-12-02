require 'test_helper'

class Chunk::SpeechmaticsChunkTest < ActiveSupport::TestCase

  should "#engine_class_name" do
    assert_equal "Speech::Engines::SpeechmaticsEngine", Chunk::SpeechmaticsChunk.engine_class_name
  end

end
