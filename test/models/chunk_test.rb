require 'test_helper'

class ChunkTest < ActiveSupport::TestCase
  should "build subclass with type" do
    assert_equal "Chunk::GoogleSpeechChunk", Chunk.new(type: "Chunk::GoogleSpeechChunk").class.name
    assert_equal "Chunk::GoogleSpeechChunk", Chunk.new(type: "google_speech_chunk").class.name
    assert_equal "Chunk::GoogleSpeechChunk", Chunk.new(type: "google_speech").class.name

    assert_equal "Chunk::AttSpeechChunk", Chunk.new(type: :att_speech).class.name
    assert_equal "Chunk::NuanceDragonChunk", Chunk.new(type: :nuance_dragon).class.name

    assert_equal "Chunk::PocketsphinxChunk", Chunk.new(type: :pocketsphinx).class.name
    assert_equal "Chunk::MechanicalTurkChunk", Chunk.new(type: :mechanical_turk).class.name
  end

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
      assert_equal [:any_of_type, :any_of_processing_status, :none_of_processing_status,
        :sort_order, :reverse_sort, :offset, :limit, :any_of_ingest_iteration,
        :any_of_position, :is_root, :score_lt, :score_gt, :score_lteq, :score_gteq,
        :ingest_id, :none_of_ingest_ids].to_set, Chunk.scopes.to_set
    end

    should "have any_of_processing_status" do
      @chunk.update_attribute(:processing_status, Speech::AudioSplitter::AudioChunk::STATUS_ENCODED)
      assert_equal true, Chunk.any_of_processing_status([Speech::AudioSplitter::AudioChunk::STATUS_ENCODED]).include?(@chunk)
    end

    should "have none_of_processing_status" do
      @chunk.update_attribute(:processing_status, Speech::AudioSplitter::AudioChunk::STATUS_ENCODED)
      assert_equal false, Chunk.none_of_processing_status([Speech::AudioSplitter::AudioChunk::STATUS_ENCODED]).include?(@chunk)
    end

    context "#sort_order" do
      should "position => asc" do
        @chunk.update_attributes(processing_status: Speech::AudioSplitter::AudioChunk::STATUS_ENCODED,
          position: 999)
        assert_equal [@chunk], Chunk.sort_order("position" => "asc").reverse_sort("true").limit(1)
      end

      should "random => asc" do
        Chunk.destroy_all
        chunk = FactoryGirl.create(:chunk_pocketsphinx)
        assert_equal [chunk], Chunk.sort_order("random" => "asc").limit(1)
      end
    end

    should "have any_of_type" do
      ps = FactoryGirl.create(:chunk_pocketsphinx)
      assert_equal [ps], Chunk.any_of_type("pocketsphinx").limit(1)
      assert_equal [ps], Chunk.any_of_type("Chunk::PocketsphinxChunk").limit(1)
    end

    should "have any_of_position" do
      ps = FactoryGirl.create(:chunk_pocketsphinx, position: 10)
      assert_equal [ps], Chunk.any_of_position(10).limit(1)
    end

    should "have any_of_ingest_iteration" do
      ps = FactoryGirl.create(:chunk_pocketsphinx, ingest_iteration: 2)
      assert_equal [ps], Chunk.any_of_ingest_iteration(2).limit(1)
    end

    should "have score greater than" do
      Chunk.destroy_all
      ps = FactoryGirl.create(:chunk_pocketsphinx, score: 0.95)
      assert_equal [ps], Chunk.score_gt(0.94).order(created_at: :desc).limit(1)
      assert_equal [], Chunk.score_gt(0.95).order(created_at: :desc).limit(1)
    end

    should "have score greater than or equal" do
      Chunk.destroy_all
      ps = FactoryGirl.create(:chunk_pocketsphinx, score: 0.95)
      assert_equal [ps], Chunk.score_gteq(0.94).order(created_at: :desc).limit(1)
      assert_equal [ps], Chunk.score_gteq(0.95).order(created_at: :desc).limit(1)
    end

    should "have score less than" do
      Chunk.destroy_all
      ps = FactoryGirl.create(:chunk_pocketsphinx, score: 0.15)
      assert_equal [ps], Chunk.score_lt(0.16).order(created_at: :desc).limit(1)
      assert_equal [], Chunk.score_lt(0.15).order(created_at: :desc).limit(1)
    end

    should "have score less than or equal" do
      Chunk.destroy_all
      ps = FactoryGirl.create(:chunk_pocketsphinx, score: 0.15)
      assert_equal [ps], Chunk.score_lteq(0.16).order(created_at: :desc).limit(1)
      assert_equal [ps], Chunk.score_lteq(0.15).order(created_at: :desc).limit(1)
    end

    should "#ingest_id" do
      Chunk.destroy_all
      ps = FactoryGirl.create(:chunk_pocketsphinx)
      assert_equal [ps], Chunk.ingest_id(ps.ingest_id).order(created_at: :desc).limit(1)
      assert_equal [], Chunk.ingest_id(-1)
    end

    should "#none_of_ingest_ids" do
      Chunk.destroy_all
      ps1 = FactoryGirl.create(:chunk_pocketsphinx)
      ps2 = FactoryGirl.create(:chunk_pocketsphinx, ingest: FactoryGirl.create(:ingest_audio))
      assert_equal [ps1], Chunk.none_of_ingest_ids(ps2.ingest_id).order(created_at: :desc).limit(1)
      assert_equal [], Chunk.none_of_ingest_ids([ps1.ingest_id, ps2.ingest_id])
    end

    context "#best" do
      setup do
        @ingest = FactoryGirl.create(:ingest_audio)
        @document = @ingest.document
        @c1 = Chunk::GoogleSpeechChunk.create(:position => 1, :offset => 0,  :duration => 0.72, :text => "I hate to say", :score => 0.80, :document => @ingest.document, :ingest => @ingest)
        @c2 = Chunk::GoogleSpeechChunk.create(:position => 2, :offset => 10, :duration => 0.89, :text => "cat maths are", :score => 0.65, :document => @ingest.document, :ingest => @ingest)
        @c3 = Chunk::GoogleSpeechChunk.create(:position => 3, :offset => 20, :duration => 1.21, :text => "the cesty food in the world", :score => 0.85, :document => @ingest.document, :ingest => @ingest)

        @c4 = Chunk::AttSpeechChunk.create(:position => 1, :offset => 0,  :duration => 0.72, :text => "I have to pray", :score => 0.72, :document => @ingest.document, :ingest => @ingest)
        @c5 = Chunk::AttSpeechChunk.create(:position => 2, :offset => 10, :duration => 0.89, :text => "that macaronies are", :score => 0.78, :document => @ingest.document, :ingest => @ingest)
        @c6 = Chunk::AttSpeechChunk.create(:position => 3, :offset => 20, :duration => 1.21, :text => "the best mushrooms in the whirlwind.", :score => 0.70, :document => @ingest.document, :ingest => @ingest)

        @c7 = Chunk::NuanceDragonChunk.create(:position => 1, :offset => 0, :duration => 0.72, :text => "I have say", :score => 0.34, :document => @ingest.document, :ingest => @ingest)
        @c8 = Chunk::NuanceDragonChunk.create(:position => 2, :offset => 0, :duration => 0.89, :text => "that some macaronies are", :score => 0.63, :document => @ingest.document, :ingest => @ingest)
        @c9 = Chunk::NuanceDragonChunk.create(:position => 3, :offset => 0, :duration => 1.21, :text => "the best food in the world", :score => 0.87, :document => @ingest.document, :ingest => @ingest)
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
    assert_equal "Chunk::GoogleSpeechChunk", Chunk.class_name_from_engine_class_for("Speech::Engines::GoogleSpeechEngine")
    assert_equal "Chunk::AttSpeechChunk", Chunk.class_name_from_engine_class_for("Speech::Engines::AttSpeechEngine")
    assert_equal "Chunk::NuanceDragonChunk", Chunk.class_name_from_engine_class_for("Speech::Engines::NuanceDragonEngine")
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
      assert_difference "Chunk::GoogleSpeechChunk.count", 1 do
        @ingest.document.chunks.create(@attributes.merge({:type => "Chunk::GoogleSpeechChunk"}))
        assert_equal Chunk::GoogleSpeechChunk, @ingest.chunks.first.class
      end
    end

    should "create AttSpeech segment" do
      assert_difference "Chunk::AttSpeechChunk.count", 1 do
        @ingest.document.chunks.create(@attributes.merge({:type => "Chunk::AttSpeechChunk"}))
        assert_equal Chunk::AttSpeechChunk, @ingest.chunks.first.class
      end
    end

    should "create NuanceDragon segment" do
      assert_difference "Chunk::NuanceDragonChunk.count", 1 do
        @ingest.document.chunks.create(@attributes.merge({:type => "Chunk::NuanceDragonChunk"}))
        assert_equal Chunk::NuanceDragonChunk, @ingest.chunks.first.class
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
    chunk = Chunk::PocketsphinxChunk.create(FactoryGirl.attributes_for(:chunk).merge(document: document))
    assert_equal "de-DE", chunk.locale
  end
end
