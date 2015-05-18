require 'test_helper'

class ChunkTest < ActiveSupport::TestCase
  context "associations" do
    should belong_to :document
    should have_one(:tracking).dependent(:destroy)
    should have_one(:track).through(:tracking)
  end

  context "delegate" do
    setup do
      @chunk = FactoryGirl.create(:chunk)
    end

    should "delegate to document track" do
     # assert_equal @chunk.document.track, @chunk.track
    end
  end

  context "validations" do
    should validate_presence_of :document
    should validate_presence_of :offset
  end

  context "scopes" do
    setup do
      @chunk = FactoryGirl.create(:chunk)
    end

    should "have filtered scopes" do
      assert_equal [:any_of_type, :any_of_processing_status, :none_of_processing_status, :sort_order, :reverse_sort, :offset, :limit, :any_of_ingest_iteration, :any_of_position, :is_root].to_set,
        Chunk.scopes.to_set
    end

    should "have any_of_processing_status" do
      @chunk.update_attribute(:processing_status, Speech::AudioSplitter::AudioChunk::STATUS_ENCODED)
      assert_equal true, Chunk.any_of_processing_status([Speech::AudioSplitter::AudioChunk::STATUS_ENCODED]).include?(@chunk)
    end

    should "have none_of_processing_status" do
      @chunk.update_attribute(:processing_status, Speech::AudioSplitter::AudioChunk::STATUS_ENCODED)
      assert_equal false, Chunk.none_of_processing_status([Speech::AudioSplitter::AudioChunk::STATUS_ENCODED]).include?(@chunk)
    end

    should "have sort_order" do
      @chunk.update_attributes(processing_status: Speech::AudioSplitter::AudioChunk::STATUS_ENCODED,
        position: 999)
      assert_equal [@chunk], Chunk.sort_order("position" => "asc").reverse_sort("true").limit(1)
    end

    should "have any_of_type" do
      ps = FactoryGirl.create(:chunk_pocketsphinx)
      assert_equal [ps], Chunk.any_of_type("pocketsphinx").limit(1)
      assert_equal [ps], Chunk.any_of_type("Chunk::Pocketsphinx").limit(1)
    end

    should "have any_of_position" do
      ps = FactoryGirl.create(:chunk_pocketsphinx, position: 10)
      assert_equal [ps], Chunk.any_of_position(10).limit(1)
    end

    should "have any_of_ingest_iteration" do
      ps = FactoryGirl.create(:chunk_pocketsphinx, ingest_iteration: 2)
      assert_equal [ps], Chunk.any_of_ingest_iteration(2).limit(1)
    end

    context "#best" do
      setup do
        @ingest = FactoryGirl.create(:ingest_audio)
        @document = @ingest.document
        @c1 = Chunk::GoogleSpeech.create(:position => 1, :offset => 0,  :duration => 0.72, :text => "I hate to say", :score => 0.80, :document => @ingest.document, :ingest => @ingest)
        @c2 = Chunk::GoogleSpeech.create(:position => 2, :offset => 10, :duration => 0.89, :text => "cat maths are", :score => 0.65, :document => @ingest.document, :ingest => @ingest)
        @c3 = Chunk::GoogleSpeech.create(:position => 3, :offset => 20, :duration => 1.21, :text => "the cesty food in the world", :score => 0.85, :document => @ingest.document, :ingest => @ingest)

        @c4 = Chunk::AttSpeech.create(:position => 1, :offset => 0,  :duration => 0.72, :text => "I have to pray", :score => 0.72, :document => @ingest.document, :ingest => @ingest)
        @c5 = Chunk::AttSpeech.create(:position => 2, :offset => 10, :duration => 0.89, :text => "that macaronies are", :score => 0.78, :document => @ingest.document, :ingest => @ingest)
        @c6 = Chunk::AttSpeech.create(:position => 3, :offset => 20, :duration => 1.21, :text => "the best mushrooms in the whirlwind.", :score => 0.70, :document => @ingest.document, :ingest => @ingest)

        @c7 = Chunk::NuanceDragon.create(:position => 1, :offset => 0, :duration => 0.72, :text => "I have say", :score => 0.34, :document => @ingest.document, :ingest => @ingest)
        @c8 = Chunk::NuanceDragon.create(:position => 2, :offset => 0, :duration => 0.89, :text => "that some macaronies are", :score => 0.63, :document => @ingest.document, :ingest => @ingest)
        @c9 = Chunk::NuanceDragon.create(:position => 3, :offset => 0, :duration => 1.21, :text => "the best food in the world", :score => 0.87, :document => @ingest.document, :ingest => @ingest)
      end

      should "scope best scores" do
        assert_equal 3, @ingest.chunks.best.count
        assert_equal [@c1, @c5, @c9], @ingest.chunks.best
      end

      should "transform chunks to best text string" do
        assert_equal "I hate to say that macaronies are the best food in the world", @ingest.chunks.best.text
      end

      should "transform chunks to rich_text JSON" do
        assert_equal 3, @ingest.chunks.best.rich_text.size
        assert_equal "I hate to say", @ingest.chunks.best.rich_text[0]['insert']
        assert_equal 0.0, @ingest.chunks.best.rich_text[0]['attributes']['offset']
      end
    end
  end # context "scopes"

  should "have response" do
    segment = FactoryGirl.create(:chunk)
    assert_equal 0, segment.response['status']
    assert_equal "I like pickles", segment.text
    assert_equal 0.59, segment.score
  end

  should "slug length" do
    chunk = FactoryGirl.create(:chunk)
    assert_equal 40, chunk.slug.length
  end

  should "delegate to document's title" do
    chunk = FactoryGirl.create(:chunk)
    assert_equal chunk.document.title, chunk.title
  end

  should "get class from engine name" do
    assert_equal "Chunk::GoogleSpeech", Chunk.type_from_engine_class_for("Speech::Engines::GoogleSpeechEngine")
    assert_equal "Chunk::AttSpeech", Chunk.type_from_engine_class_for("Speech::Engines::AttSpeechEngine")
    assert_equal "Chunk::NuanceDragon", Chunk.type_from_engine_class_for("Speech::Engines::NuanceDragonEngine")
  end

  context "speech engines" do
    setup do
      @ingest = FactoryGirl.create(:ingest_audio)
      @attributes = {
        :position          => 1,
        :offset            => 0,
        :duration          => 5,
        :text              => "I like pickles",
        :score             => 0.59,
        :response          => {status: 3},
        :processing_errors => [],
        :processing_status => 3
      }
    end

    should "create GoogleSpeech segment" do
      assert_difference "Chunk::GoogleSpeech.count", 1 do
        @ingest.document.chunks.create(@attributes.merge({:type => "Chunk::GoogleSpeech"}))
        assert_equal Chunk::GoogleSpeech, @ingest.chunks.first.class
      end
    end

    should "create AttSpeech segment" do
      assert_difference "Chunk::AttSpeech.count", 1 do
        @ingest.document.chunks.create(@attributes.merge({:type => "Chunk::AttSpeech"}))
        assert_equal Chunk::AttSpeech, @ingest.chunks.first.class
      end
    end

    should "create NuanceDragon segment" do
      assert_difference "Chunk::NuanceDragon.count", 1 do
        @ingest.document.chunks.create(@attributes.merge({:type => "Chunk::NuanceDragon"}))
        assert_equal Chunk::NuanceDragon, @ingest.chunks.first.class
      end
    end
  end

  should "have uid" do
    chunk = FactoryGirl.create(:chunk)
    assert_not_nil chunk.uid
    assert_equal 36, chunk.uid.length
  end

  should "set start_at and end_at" do
    chunk = FactoryGirl.create(:chunk_with_ingest)
    assert_equal chunk.ingest.upload.recorded_at + chunk.offset, chunk.start_at
    assert_equal chunk.ingest.upload.recorded_at + chunk.offset + chunk.duration, chunk.end_at
  end

  should "not be root?" do
    chunk = FactoryGirl.create(:chunk)
    assert_equal false, chunk.is_root?
    assert_equal false, chunk.is_root
  end

  should "set locale based on root document" do
    document = FactoryGirl.create(:document, locale: "de-DE")
    chunk = Chunk::Pocketsphinx.create(FactoryGirl.attributes_for(:chunk).merge(document: document))
    assert_equal "de-DE", chunk.locale
  end
end
