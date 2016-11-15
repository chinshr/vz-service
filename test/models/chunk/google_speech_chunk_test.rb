require 'test_helper'

class Chunk::GoogleSpeechChunkTest < ActiveSupport::TestCase

  should "#engine_class_name" do
    assert_equal "Speech::Engines::GoogleSpeechEngine", Chunk::GoogleSpeechChunk.engine_class_name
  end

end
