require 'test_helper'

class Speech::AudioToTextTest < ActiveSupport::TestCase
  should "instantiate" do
    audio = Speech::AudioToText.new("#{Rails.root}/test/fixtures/i-like-pickles.wav", 
      :engine => :base, :verbose => false)
    assert_equal false, audio.engine.blank?
    # assert_exception do
    #   audio.to_json
    # end
  end
end
