require 'test_helper'

class Chunk::GoogleCloudSpeechChunkTest < ActiveSupport::TestCase

  should "#engine_class_name" do
    assert_equal "Speech::Engines::GoogleCloudSpeechEngine", Chunk::GoogleCloudSpeechChunk.engine_class_name
  end

end
