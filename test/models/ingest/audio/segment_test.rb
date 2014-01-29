require 'test_helper'

class Ingest::Audio::SegmentTest < ActiveSupport::TestCase
  context "associations" do
    should belong_to :ingest
  end
  
  context "validations" do
    should validate_presence_of :ingest
    should validate_presence_of :offset
  end
  
  should "have response" do
    segment = FactoryGirl.create(:ingest_audio_segment)
    assert_equal 0, segment.response['status']
    assert_equal "I like pickles", segment.best_text
    assert_equal 0.59, segment.best_score
  end
end
