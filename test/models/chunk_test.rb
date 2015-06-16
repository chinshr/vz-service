require 'test_helper'

class ChunkTest < ActiveSupport::TestCase
  context "build" do
    should "subclass with type" do
      assert_equal "Chunk::GoogleSpeechChunk", Chunk.new(type: "Chunk::GoogleSpeechChunk").class.name
      assert_equal "Chunk::GoogleSpeechChunk", Chunk.new(type: "google_speech_chunk").class.name
      assert_equal "Chunk::GoogleSpeechChunk", Chunk.new(type: "google_speech").class.name

      assert_equal "Chunk::AttSpeechChunk", Chunk.new(type: :att_speech).class.name
      assert_equal "Chunk::NuanceDragonChunk", Chunk.new(type: :nuance_dragon).class.name

      assert_equal "Chunk::PocketsphinxChunk", Chunk.new(type: :pocketsphinx).class.name
      assert_equal "Chunk::MechanicalTurkChunk", Chunk.new(type: :mechanical_turk).class.name
    end

    should "chunk with master_segment" do
      assert_difference "Segment::ChunkSegment.count" do
        document = FactoryGirl.create(:document)
        ch = Chunk::PocketsphinxChunk.new({
          text: "I like pickles",
          document_id: document.id,
          position: 2,
          offset: 4.34
        })
        assert_equal true, ch.save
        assert_equal false, ch.master_segment.new_record?
        assert_equal true, ch.master_segment.is_master?
        assert_equal document, ch.document
        assert_equal ch.master_segment.position, ch.position
        assert_equal 4.34, ch.offset
      end
    end

    should "create chunk with document via document_id" do
      Segment.destroy_all
      @ingest   = FactoryGirl.create(:ingest_audio)
      @document = @ingest.document

      @t1 = Track.create(FactoryGirl.attributes_for(:track, type: "chunk_track", s3_url: "http://t1", duration: 2))
      @t2 = Track.create(FactoryGirl.attributes_for(:track, type: "chunk_track", s3_url: "http://t2", duration: 3))

      sc = Chunk::PocketsphinxChunk.create({
        position: 1, text: "now the earth was formed this and empty",
        offset: 0.28, score: 0.45,
        document_id: @document.id, ingest: @ingest, track: @t1
      })

      cc = Chunk::CaptchaChunk.create({
        position: 1, text: "now the earth was formed this and empty",
        offset: 0.28, score: 0.45,
        document_id: sc.id, ingest: @ingest, track: @t2, chunk_ids: [sc.id]
      })

      assert_equal sc, cc.document
      assert_equal true, cc.chunks.include?(sc)
    end

    should "captcha_chunk with source and reference chunks" do
      Segment.destroy_all
      @ingest   = FactoryGirl.create(:ingest_audio)
      @document = @ingest.document

      @sc_t1    = Track.create(FactoryGirl.attributes_for(:track, type: "chunk_track", s3_url: "http://sc_t1", duration: 2))
      @cc_t1    = Track.create(FactoryGirl.attributes_for(:track, type: "chunk_track", s3_url: "http://cc_t1", duration: 6))

      sc1 = Chunk::PocketsphinxChunk.create({
        position: 1, text: "now the earth was formed this and empty",
        offset: 0.28, score: 0.45,
        document: @document, ingest: @ingest, track: @sc_t1
      })

      rc1 = FactoryGirl.create(:chunk_google_speech, score: 0.99,
        text: "I like pickles")

      cc1 = @ingest.chunks.create({type: "captcha_chunk",
        text: "now the earth was formed this and empty|I like pickles",
        position: 1, offset: 0.28, score: 0.45,
        document: sc1, ingest: @ingest, track: @cc_t1,
        chunk_ids: [sc1.id, rc1.id]
      })

      assert_equal 2, cc1.chunks.count
      assert_equal [sc1, rc1].to_set, cc1.chunks.to_set

      # assert_equal sc1.track, cc1.chunks[0].track
      # assert_equal rc1.track, cc1.chunks[1].track

      assert_equal nil, cc1.child_segments[0].position
      assert_equal nil, cc1.child_segments[1].position

      assert_equal @cc_t1, cc1.track
      assert_equal sc1, cc1.document
      assert_equal @document, sc1.document

      assert_equal true, cc1.parent_segments[0].is_master?
      assert_equal false, cc1.child_segments[0].is_master?
      assert_equal false, cc1.child_segments[1].is_master?
    end
  end

  context "associations" do
    should have_one(:master_chunk_segment).dependent(:destroy)
    should have_one(:document).through(:master_chunk_segment)
    should have_one(:ingest).through(:master_chunk_segment)
    should have_one(:track).through(:master_chunk_segment)

    should "accepts_nested_attributes_for :track" do
      document = FactoryGirl.create(:document_with_ingest)
      assert_difference "Chunk.count", 1 do
        assert_difference "Segment::ChunkSegment.count", 1 do
          assert_difference "Track::ChunkTrack.count", 1 do
            chunk = document.chunks.create(text: "test", offset: 0, position: 1,
              track_attributes: FactoryGirl.attributes_for(:track))
          end
        end
      end
    end
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
      assert_equal [:any_of_types, :none_of_types, :any_of_processing_status, :none_of_processing_status,
        :sort_order, :reverse_sort, :offset, :limit, :any_of_ingest_iterations,
        :any_of_positions, :is_root, :score_lt, :score_gt, :score_lteq, :score_gteq,
        :duration_lt, :duration_gt, :duration_lteq, :duration_gteq, :ingest_id, :none_of_ingest_ids,
        :any_of_locales].to_set, Chunk.scopes.to_set
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

    should "#any_of_types" do
      ps = FactoryGirl.create(:chunk_pocketsphinx)
      assert_equal [ps], Chunk.any_of_types("pocketsphinx").limit(1)
      assert_equal [ps], Chunk.any_of_types([:"pocketsphinx"]).limit(1)
      assert_equal [ps], Chunk.any_of_types("pocketsphinx_chunk").limit(1)
      assert_equal [ps], Chunk.any_of_types("Chunk::PocketsphinxChunk").limit(1)
    end

    should "#none_of_types" do
      Chunk.destroy_all
      ch1 = FactoryGirl.create(:chunk_pocketsphinx)
      ch2 = FactoryGirl.create(:chunk_mechanical_turk)
      assert_equal [ch1], Chunk.none_of_types("mechanical_turk").limit(1)
      assert_equal [ch2], Chunk.none_of_types([:"pocketsphinx"]).limit(1)
      assert_equal [ch2], Chunk.none_of_types("Chunk::PocketsphinxChunk").limit(1)
      assert_equal [], Chunk.none_of_types([:pocketsphinx, :mechanical_turk])
    end

    should "#any_of_positions" do
      Chunk.destroy_all
      ps = FactoryGirl.create(:chunk_pocketsphinx, position: 10)
      assert_equal [ps], Chunk.any_of_positions(10).limit(1)
      assert_equal [ps], Chunk.any_of_positions([10]).limit(1)
    end

    should "#any_of_ingest_iterations" do
      Chunk.destroy_all
      ps = FactoryGirl.create(:chunk_pocketsphinx, ingest_iteration: 2)
      assert_equal [ps], Chunk.any_of_ingest_iterations(2).limit(1)
      assert_equal [ps], Chunk.any_of_ingest_iterations([2]).limit(1)
    end

    context "score comparison" do
      should "#score_lt" do
        Chunk.destroy_all
        ps = FactoryGirl.create(:chunk_pocketsphinx, score: 0.15)
        assert_equal [ps], Chunk.score_lt(0.16).order(created_at: :desc).limit(1)
        assert_equal [], Chunk.score_lt(0.15).order(created_at: :desc).limit(1)
      end

      should "#score_lteq" do
        Chunk.destroy_all
        ps = FactoryGirl.create(:chunk_pocketsphinx, score: 0.15)
        assert_equal [ps], Chunk.score_lteq(0.16).order(created_at: :desc).limit(1)
        assert_equal [ps], Chunk.score_lteq(0.15).order(created_at: :desc).limit(1)
      end

      should "#score_gt" do
        Chunk.destroy_all
        ps = FactoryGirl.create(:chunk_pocketsphinx, score: 0.95)
        assert_equal [ps], Chunk.score_gt(0.94).order(created_at: :desc).limit(1)
        assert_equal [], Chunk.score_gt(0.95).order(created_at: :desc).limit(1)
      end

      should "#score_gteq" do
        Chunk.destroy_all
        ps = FactoryGirl.create(:chunk_pocketsphinx, score: 0.95)
        assert_equal [ps], Chunk.score_gteq(0.94).order(created_at: :desc).limit(1)
        assert_equal [ps], Chunk.score_gteq(0.95).order(created_at: :desc).limit(1)
      end
    end

    context "duration comparison" do
      setup do
        Chunk.destroy_all
        Track.destroy_all
      end

      should "#duration_lt" do
        ps = FactoryGirl.create(:chunk_pocketsphinx)
        ps.track.update_attributes(duration: 0.15)
        assert_equal [ps], Chunk.duration_lt(0.16).order(created_at: :desc).limit(1)
        assert_equal [], Chunk.duration_lt(0.15).order(created_at: :desc).limit(1)
      end

      should "#duration_lteq" do
        ps = FactoryGirl.create(:chunk_pocketsphinx)
        ps.track.update_attributes(duration: 0.15)
        assert_equal [ps], Chunk.duration_lteq(0.16).order(created_at: :desc).limit(1)
        assert_equal [ps], Chunk.duration_lteq(0.15).order(created_at: :desc).limit(1)
      end

      should "#duration_gt" do
        ps = FactoryGirl.create(:chunk_pocketsphinx)
        ps.track.update_attributes(duration: 0.95)
        assert_equal [ps], Chunk.duration_gt(0.94).order(created_at: :desc).limit(1)
        assert_equal [], Chunk.duration_gt(0.95).order(created_at: :desc).limit(1)
      end

      should "#duration_gteq" do
        ps = FactoryGirl.create(:chunk_pocketsphinx)
        ps.track.update_attributes(duration: 0.95)
        assert_equal [ps], Chunk.duration_gteq(0.94).order(created_at: :desc).limit(1)
        assert_equal [ps], Chunk.duration_gteq(0.95).order(created_at: :desc).limit(1)
      end
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

    should "#any_of_locales" do
      Chunk.destroy_all
      ps1 = FactoryGirl.create(:chunk_pocketsphinx, locale: "en-GB")
      ps2 = FactoryGirl.create(:chunk_pocketsphinx, locale: "en-US")
      ps3 = FactoryGirl.create(:chunk_pocketsphinx, locale: "en-AU")
      ps4 = FactoryGirl.create(:chunk_pocketsphinx, locale: "de-DE")
      assert_equal [ps2], Chunk.any_of_locales("en-US")
      assert_equal [ps2], Chunk.any_of_locales("en-us")
      assert_equal [ps1, ps2, ps3], Chunk.any_of_locales("en")
      assert_equal [ps4], Chunk.any_of_locales("de")
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
        assert_equal 9, @ingest.document.chunks.count
        assert_equal 3, @ingest.document.chunks.best.count
        assert_equal [@c1, @c5, @c9], @ingest.document.chunks.best
      end

      should "transform chunks to best text string" do
        assert_equal "I hate to say that macaronies are the best food in the world", @ingest.document.chunks.best.text
      end

      should "transform chunks to rich_text JSON" do
        assert_equal 3, @ingest.document.chunks.best.rich_text.size
        assert_equal "I hate to say", @ingest.document.chunks.best.rich_text[0]['insert']
        assert_equal 0.0, @ingest.document.chunks.best.rich_text[0]['attributes']['offset']
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
        # :duration          => 5,
        :text              => "I like pickles",
        :score             => 0.59,
        :response          => {status: 3},
        :processing_errors => [],
        :processing_status => 3
      }
    end

    should "create GoogleSpeech segment" do
      assert_difference "Chunk::GoogleSpeechChunk.count", 1 do
        @ingest.document.chunks.create(@attributes.merge({type: "Chunk::GoogleSpeechChunk", ingest: @ingest}))
        assert_equal Chunk::GoogleSpeechChunk, @ingest.chunks.first.class
      end
    end

    should "create AttSpeech segment" do
      assert_difference "Chunk::AttSpeechChunk.count", 1 do
        assert_difference "Segment::ChunkSegment.count", 1 do
          ch = @ingest.chunks.create(@attributes.merge({type: "Chunk::AttSpeechChunk"}))
          assert_equal Chunk::AttSpeechChunk, @ingest.chunks.reload.first.class
          assert_equal @ingest, ch.ingest
          assert_equal @ingest.document, ch.document
        end
      end
    end

    should "create NuanceDragon segment" do
      assert_difference "Chunk::NuanceDragonChunk.count", 1 do
        @ingest.document.chunks.create(@attributes.merge({type: "Chunk::NuanceDragonChunk", ingest: @ingest}))
        assert_equal Chunk::NuanceDragonChunk, @ingest.chunks.first.class
      end
    end
  end

  should "have uid" do
    chunk = FactoryGirl.create(:chunk)
    assert_not_nil chunk.uid
    assert_equal 36, chunk.uid.length
  end

  context "#set_default_locale" do
    setup do
      @document   = FactoryGirl.create(:document, locale: "de-DE")
      @attributes = FactoryGirl.attributes_for(:chunk).merge(document: @document)
    end

    should "locale based on root document" do
      chunk = Chunk::PocketsphinxChunk.create(@attributes)
      assert_equal "de-DE", chunk.locale
    end

    should "set manually" do
      chunk = Chunk::PocketsphinxChunk.create(@attributes.merge(locale: "es-ES"))
      assert_equal "es-ES", chunk.locale
    end
  end

  should "not be root?" do
    chunk = FactoryGirl.create(:chunk)
    assert_equal false, chunk.is_root?
    assert_equal false, chunk.is_root
  end
end
