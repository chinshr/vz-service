require 'test_helper'

class Document::SegmentTest < ActiveSupport::TestCase
  context "associations" do
    should belong_to :document
  end
  
  context "validations" do
    should validate_presence_of :document
    should validate_presence_of :offset
  end
  
  should "have response" do
    segment = FactoryGirl.create(:document_segment)
    assert_equal 0, segment.response['status']
    assert_equal "I like pickles", segment.text
    assert_equal 0.59, segment.score
  end
end
