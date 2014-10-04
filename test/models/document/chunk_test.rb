require 'test_helper'

class Document::ChunkTest < ActiveSupport::TestCase
  context "associations" do
    should belong_to :document
  end
  
  context "validations" do
    should validate_presence_of :document
    should validate_presence_of :offset
  end
  
  should "have response" do
    segment = FactoryGirl.create(:document_chunk)
    assert_equal 0, segment.response['status']
    assert_equal "I like pickles", segment.text
    assert_equal 0.59, segment.score
  end
  
  context "scopes" do
    setup do
      @document = FactoryGirl.create(:document)
      @c1 = Document::Chunk::GoogleSpeech.create(:position => 1, :offset => 0,  :text => "I hate to say", :score => 0.80, :document => @document)
      @c2 = Document::Chunk::GoogleSpeech.create(:position => 2, :offset => 10, :text => "cat maths are", :score => 0.65, :document => @document)
      @c3 = Document::Chunk::GoogleSpeech.create(:position => 3, :offset => 20, :text => "the cesty food in the world", :score => 0.85, :document => @document)

      @c4 = Document::Chunk::AttSpeech.create(:position => 1, :offset => 0,  :text => "I have to pray", :score => 0.72, :document => @document)
      @c5 = Document::Chunk::AttSpeech.create(:position => 2, :offset => 10, :text => "that macaronies are", :score => 0.78, :document => @document)
      @c6 = Document::Chunk::AttSpeech.create(:position => 3, :offset => 20, :text => "the best mushrooms in the whirlwind.", :score => 0.70, :document => @document)

      @c7 = Document::Chunk::NuanceDragon.create(:position => 1, :offset => 0,  :text => "I have say", :score => 0.34, :document => @document)
      @c8 = Document::Chunk::NuanceDragon.create(:position => 2, :offset => 0,  :text => "that some macaronies are", :score => 0.63, :document => @document)
      @c9 = Document::Chunk::NuanceDragon.create(:position => 3, :offset => 0,  :text => "the best food in the world", :score => 0.87, :document => @document)
    end
    
    should "scope best scores" do
      assert_equal 3, @document.chunks.best.count
      assert_equal [@c1, @c5, @c9], @document.chunks.best
    end

    should "scope worst scores" do
      assert_equal 3, @document.chunks.worst.count
      assert_equal [@c7, @c8, @c6], @document.chunks.worst
    end
    
    should "transform chunks to best text string" do
      assert_equal "I hate to say that macaronies are the best food in the world", @document.chunks.best.text
    end

    should "transform chunks to worst text string" do
      assert_equal "I have say that some macaronies are the best mushrooms in the whirlwind.", @document.chunks.worst.text
    end
  end
  
  should "get class from engine name" do
    assert_equal "Document::Chunk::GoogleSpeech", Document::Chunk.type_from_engine_class_for("Speech::Engines::GoogleSpeechEngine")
    assert_equal "Document::Chunk::AttSpeech", Document::Chunk.type_from_engine_class_for("Speech::Engines::AttSpeechEngine")
    assert_equal "Document::Chunk::NuanceDragon", Document::Chunk.type_from_engine_class_for("Speech::Engines::NuanceDragonEngine")
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
      assert_difference "Document::Chunk::GoogleSpeech.count", 1 do
        @ingest.ingestable.chunks.create(@attributes.merge({:type => "Document::Chunk::GoogleSpeech"}))
        assert_equal Document::Chunk::GoogleSpeech, @ingest.ingestable.chunks.first.class
      end
    end
    
    should "create AttSpeech segment" do
      assert_difference "Document::Chunk::AttSpeech.count", 1 do
        @ingest.ingestable.chunks.create(@attributes.merge({:type => "Document::Chunk::AttSpeech"}))
        assert_equal Document::Chunk::AttSpeech, @ingest.ingestable.chunks.first.class
      end
    end

    should "create NuanceDragon segment" do
      assert_difference "Document::Chunk::NuanceDragon.count", 1 do
        @ingest.ingestable.chunks.create(@attributes.merge({:type => "Document::Chunk::NuanceDragon"}))
        assert_equal Document::Chunk::NuanceDragon, @ingest.ingestable.chunks.first.class
      end
    end
    
  end
end
