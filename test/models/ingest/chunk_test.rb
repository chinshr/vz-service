require 'test_helper'

class Ingest::ChunkTest < ActiveSupport::TestCase
  context "associations" do
    should belong_to :ingest
  end

  context "validations" do
    should validate_presence_of :ingest
    should validate_presence_of :offset
  end

  context "scopes" do
    setup do
      @chunk = FactoryGirl.create(:ingest_chunk)
    end

    should "have filtered scopes" do
      assert_equal [:any_of_type, :any_of_processing_status, :none_of_processing_status, :sort_order, :reverse_sort, :offset, :limit].to_set,
        Ingest::Chunk.scopes.to_set
    end

    should "have any_of_processing_status" do
      @chunk.update_attribute(:processing_status, Speech::AudioSplitter::AudioChunk::STATUS_ENCODED)
      assert_equal true, Ingest::Chunk.any_of_processing_status([Speech::AudioSplitter::AudioChunk::STATUS_ENCODED]).include?(@chunk)
    end

    should "have none_of_processing_status" do
      @chunk.update_attribute(:processing_status, Speech::AudioSplitter::AudioChunk::STATUS_ENCODED)
      assert_equal false, Ingest::Chunk.none_of_processing_status([Speech::AudioSplitter::AudioChunk::STATUS_ENCODED]).include?(@chunk)
    end

    should "have sort_order" do
      @chunk.update_attribute(:processing_status, Speech::AudioSplitter::AudioChunk::STATUS_ENCODED)
      assert_equal [@chunk], Ingest::Chunk.sort_order("position" => "asc").reverse_sort("true").limit(1)
    end
  end # context "scopes"

  should "have response" do
    segment = FactoryGirl.create(:ingest_chunk)
    assert_equal 0, segment.response['status']
    assert_equal "I like pickles", segment.text
    assert_equal 0.59, segment.score
  end

  context "scopes" do
    setup do
      @ingest = FactoryGirl.create(:ingest_audio)
      @c1 = Ingest::Chunk::GoogleSpeech.create(:position => 1, :offset => 0,  :text => "I hate to say", :score => 0.80, :ingest => @ingest)
      @c2 = Ingest::Chunk::GoogleSpeech.create(:position => 2, :offset => 10, :text => "cat maths are", :score => 0.65, :ingest => @ingest)
      @c3 = Ingest::Chunk::GoogleSpeech.create(:position => 3, :offset => 20, :text => "the cesty food in the world", :score => 0.85, :ingest => @ingest)

      @c4 = Ingest::Chunk::AttSpeech.create(:position => 1, :offset => 0,  :text => "I have to pray", :score => 0.72, :ingest => @ingest)
      @c5 = Ingest::Chunk::AttSpeech.create(:position => 2, :offset => 10, :text => "that macaronies are", :score => 0.78, :ingest => @ingest)
      @c6 = Ingest::Chunk::AttSpeech.create(:position => 3, :offset => 20, :text => "the best mushrooms in the whirlwind.", :score => 0.70, :ingest => @ingest)

      @c7 = Ingest::Chunk::NuanceDragon.create(:position => 1, :offset => 0,  :text => "I have say", :score => 0.34, :ingest => @ingest)
      @c8 = Ingest::Chunk::NuanceDragon.create(:position => 2, :offset => 0,  :text => "that some macaronies are", :score => 0.63, :ingest => @ingest)
      @c9 = Ingest::Chunk::NuanceDragon.create(:position => 3, :offset => 0,  :text => "the best food in the world", :score => 0.87, :ingest => @ingest)
    end

    should "scope best scores" do
      assert_equal 3, @ingest.chunks.best.count
      assert_equal [@c1, @c5, @c9], @ingest.chunks.best
    end

    should "transform chunks to best text string" do
      assert_equal "I hate to say that macaronies are the best food in the world", @ingest.chunks.best.text
    end

    should "transform chunks to rich_text JSON" do
      assert_equal [{"insert"=>"I hate to say", "attributes"=>{"offset"=>0}}, {"insert"=>"that macaronies are", "attributes"=>{"offset"=>10}}, {"insert"=>"the best food in the world", "attributes"=>{"offset"=>0}}], @ingest.chunks.best.rich_text
    end
  end

  should "get class from engine name" do
    assert_equal "Ingest::Chunk::GoogleSpeech", Ingest::Chunk.type_from_engine_class_for("Speech::Engines::GoogleSpeechEngine")
    assert_equal "Ingest::Chunk::AttSpeech", Ingest::Chunk.type_from_engine_class_for("Speech::Engines::AttSpeechEngine")
    assert_equal "Ingest::Chunk::NuanceDragon", Ingest::Chunk.type_from_engine_class_for("Speech::Engines::NuanceDragonEngine")
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
      assert_difference "Ingest::Chunk::GoogleSpeech.count", 1 do
        @ingest.chunks.create(@attributes.merge({:type => "Ingest::Chunk::GoogleSpeech"}))
        assert_equal Ingest::Chunk::GoogleSpeech, @ingest.chunks.first.class
      end
    end

    should "create AttSpeech segment" do
      assert_difference "Ingest::Chunk::AttSpeech.count", 1 do
        @ingest.chunks.create(@attributes.merge({:type => "Ingest::Chunk::AttSpeech"}))
        assert_equal Ingest::Chunk::AttSpeech, @ingest.chunks.first.class
      end
    end

    should "create NuanceDragon segment" do
      assert_difference "Ingest::Chunk::NuanceDragon.count", 1 do
        @ingest.chunks.create(@attributes.merge({:type => "Ingest::Chunk::NuanceDragon"}))
        assert_equal Ingest::Chunk::NuanceDragon, @ingest.chunks.first.class
      end
    end

  end
end
