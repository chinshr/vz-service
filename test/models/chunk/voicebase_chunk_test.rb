require 'test_helper'

class Chunk::VoiceBaseChunkTest < ActiveSupport::TestCase

  should "#engine_class_name" do
    assert_equal "Speech::Engines::VoicebaseEngine", Chunk::VoiceBaseChunk.engine_class_name
  end

end
