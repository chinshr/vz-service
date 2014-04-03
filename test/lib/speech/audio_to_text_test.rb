require 'test_helper'

class Speech::AudioToTextTest < ActiveSupport::TestCase
  should "convert audio to text" do
    audio = Speech::AudioToText.new(File.expand_path(File.join(File.dirname(__FILE__),"samples/i-like-pickles.wav")))
    assert_equal "I like pickles", audio.to_text
  end

  should "convert longer audio to text" do
    audio = Speech::AudioToText.new(File.expand_path(File.join(File.dirname(__FILE__),"/SampleAudio.wav")), :verbose => true)
    puts audio.to_text
    puts audio.score
    puts audio.segments
  end
end
