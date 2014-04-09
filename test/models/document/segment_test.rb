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
  
  context "speech engines" do
    setup do
      @ingest = FactoryGirl.create(:ingest_audio)
      @attributes = {
        :position          => 1,
        :offset            => 0,
        :duration          => 5,
        :start_time        => 0.to_f,
        :end_time          => 5.to_f,
        :text              => "I like pickles",
        :score             => 0.59,
        :response          => {status: 3},
        :processing_errors => [],
        :processing_status => 3
      }
    end
    
    should "create GoogleSpeech segment" do
      assert_difference "Document::Segment::GoogleSpeech.count", 1 do
        @ingest.ingestable.segments.create(@attributes.merge({:type => "Document::Segment::GoogleSpeech"}))
        assert_equal Document::Segment::GoogleSpeech, @ingest.ingestable.segments.first.class
      end
    end
    
    should "create AttSpeech segment" do
      assert_difference "Document::Segment::AttSpeech.count", 1 do
        @ingest.ingestable.segments.create(@attributes.merge({:type => "Document::Segment::AttSpeech"}))
        assert_equal Document::Segment::AttSpeech, @ingest.ingestable.segments.first.class
      end
    end

    should "create NuanceDragon segment" do
      assert_difference "Document::Segment::NuanceDragon.count", 1 do
        @ingest.ingestable.segments.create(@attributes.merge({:type => "Document::Segment::NuanceDragon"}))
        assert_equal Document::Segment::NuanceDragon, @ingest.ingestable.segments.first.class
      end
    end
    
  end
end
