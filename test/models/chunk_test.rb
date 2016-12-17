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
      @ingest   = FactoryGirl.create(:media_ingest_as_audio)
      @document = @ingest.document

      @t1 = Track.create(FactoryGirl.attributes_for(:track, type: "chunk_track", s3_url: "http://t1", duration: 2))
      @t2 = Track.create(FactoryGirl.attributes_for(:track, type: "chunk_track", s3_url: "http://t2", duration: 3))

      sc = Chunk::PocketsphinxChunk.create({
        position: 1, text: "now the earth was formed this and empty",
        offset: 0.28, score: 0.45,
        document_id: @document.id, ingest: @ingest, track: @t1
      })

      Chunk::MechanicalTurkChunk.stubs(:create_hit).returns(true)

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
      @ingest   = FactoryGirl.create(:media_ingest_as_audio)
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

      Chunk::MechanicalTurkChunk.stubs(:create_hit).returns(true)

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
        :sort_order, :reverse_sort, :offset, :limit, :user_id, :any_of_ingest_iterations,
        :any_of_positions, :is_root, :score_lt, :score_gt, :score_lteq, :score_gteq,
        :duration_lt, :duration_gt, :duration_lteq, :duration_gteq, :ingest_id, :none_of_ingest_ids,
        :any_of_locales, :any_of_status, :none_of_status, :any_of_tags, :none_of_tags,
        :created_at_gt, :created_at_gteq, :created_at_lt, :created_at_lteq,
        :updated_at_gt, :updated_at_gteq, :updated_at_lt, :updated_at_lteq,
        :published_at_gt, :published_at_gteq, :published_at_lt, :published_at_lteq].to_set, Chunk.scopes.to_set
    end

    should "have any_of_processing_status" do
      @chunk.update_attribute(:processing_status, Chunk::STATES[:encoded])
      assert_equal true, Chunk.any_of_processing_status([Chunk::STATES[:encoded]]).include?(@chunk)
    end

    should "have none_of_processing_status" do
      @chunk.update_attribute(:processing_status, Chunk::STATES[:encoded])
      assert_equal false, Chunk.none_of_processing_status([Chunk::STATES[:encoded]]).include?(@chunk)
    end

    context "#sort_order" do
      should "position => asc" do
        @chunk.update_attributes(processing_status: Chunk::STATES[:encoded],
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
      ps2 = FactoryGirl.create(:chunk_pocketsphinx, ingest: FactoryGirl.create(:media_ingest_as_audio))
      assert_equal [ps1], Chunk.none_of_ingest_ids(ps2.ingest_id).order(created_at: :desc).limit(1)
      assert_equal [], Chunk.none_of_ingest_ids([ps1.ingest_id, ps2.ingest_id])
    end

    should "#any_of_locales" do
      Chunk.destroy_all
      ps1 = FactoryGirl.create(:chunk_pocketsphinx, locale: "en-GB")
      ps2 = FactoryGirl.create(:chunk_pocketsphinx, locale: "en-US")
      ps3 = FactoryGirl.create(:chunk_pocketsphinx, locale: "en-AU")
      ps4 = FactoryGirl.create(:chunk_pocketsphinx, locale: "de-DE")
      assert_equal [ps2].to_set, Chunk.any_of_locales("en-US").to_set
      assert_equal [ps2].to_set, Chunk.any_of_locales("en-us").to_set
      assert_equal [ps1, ps2, ps3].to_set, Chunk.any_of_locales("en").to_set
      assert_equal [ps4].to_set, Chunk.any_of_locales("de").to_set
    end

    context "#best" do
      setup do
        @ingest = FactoryGirl.create(:media_ingest_as_audio)
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
        assert_equal 3, @ingest.document.best_chunks.count(:id)
        assert_equal [@c1, @c5, @c9], @ingest.document.best_chunks
      end

      should "transform chunks to best text string" do
        assert_equal "I hate to say that macaronies are the best food in the world", @ingest.document.best_chunks.text
      end

      should "transform chunks to rich_text JSON" do
        rt = @ingest.document.best_chunks.rich_text
        assert_equal 5, rt['ops'].size, "spaces between chunks"
        assert_equal "I hate to say", rt['ops'][0]['insert']
        assert_equal @ingest.document.chunks.first.send(:segment_id),
          rt['ops'][0]['attributes']['segment']
      end
    end
  end # context "scopes"

  should "have response" do
    chunk = FactoryGirl.create(:chunk)
    assert_equal 0, chunk.response.as_json['status']
    assert_equal "I like pickles", chunk.text
    assert_equal 0.59, chunk.score
  end

  context "slug" do
    should "slug_id length" do
      chunk = FactoryGirl.create(:chunk)
      assert_equal 40, chunk.slug_id.length
    end

    should "be equal slug and slug_id" do
      chunk = FactoryGirl.create(:chunk)
      assert_equal 40, chunk.slug.length
      assert_equal chunk.slug_id, chunk.slug
    end
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
      @ingest = FactoryGirl.create(:media_ingest_as_audio)
      @attributes = {
        :position          => 1,
        :offset            => 0,
        # :duration          => 5,
        :text              => "I like pickles",
        :score             => 0.59,
        :response          => {status: 3},
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

  context "response" do
    should "#version" do
      assert_equal Document::Response::VERSION, FactoryGirl.build(:chunk, :errors).response.version
    end

    should "#id" do
      assert_equal "ab345ae89f8b17d8e8298c9c7814700a-9", FactoryGirl.build(:chunk, :errors).response.id
    end

    should "#status" do
      assert_equal -1, FactoryGirl.build(:chunk, :errors).response.status
    end

    should "#errors" do
      assert_equal "Split error", FactoryGirl.build(:chunk, :errors).response.errors.first
    end

    should "#external_status" do
      assert_equal "(c21r)", FactoryGirl.build(:chunk, :errors).response.external_status
    end

    context "#hypotheses" do
      setup do
        @chunk = FactoryGirl.build(:chunk, :hypotheses)
      end

      should "get" do
        assert_not_nil @chunk.response.hypotheses
        assert_equal Document::Response::HypothesisCollection, @chunk.response.hypotheses.class
        assert_equal Document::Response::Hypothesis, @chunk.response.hypotheses[0].class
        assert_equal "I like pickles", @chunk.response.hypotheses[0].utterance
        assert_equal 0.59408695, @chunk.response.hypotheses[0].confidence
      end
    end

    context "#keywords" do
      setup do
        @chunk = FactoryGirl.build(:chunk, :keywords)
      end

      should "get" do
        assert_not_nil @chunk.response.keywords
        assert_equal Document::Response::KeywordCollection, @chunk.response.keywords.class
        assert_equal Document::Response::Keyword, @chunk.response.keywords[0].class
        assert_equal "89f8b1", @chunk.response.keywords[0].id
        assert_equal "pickle", @chunk.response.keywords[0].text
        assert_equal 0.974, @chunk.response.keywords[0].relevance
        # emotions
        assert_not_nil @chunk.response.keywords[0].emotions
        assert_equal Document::Response::Emotions, @chunk.response.keywords[0].emotions.class
        assert_equal 0.0231, @chunk.response.keywords[0].emotions.joy
        assert_equal 0.0123, @chunk.response.keywords[0].emotions.fear
        assert_equal 0.2344, @chunk.response.keywords[0].emotions.anger
        assert_equal 0.234, @chunk.response.keywords[0].emotions.disgust
        assert_equal 0.23432, @chunk.response.keywords[0].emotions.sadness
        # sentiment
        assert_not_nil @chunk.response.keywords[0].sentiment
        assert_equal Document::Response::Sentiment, @chunk.response.keywords[0].sentiment.class
        assert_equal "neutral", @chunk.response.keywords[0].sentiment.type
        assert_equal 0.08423, @chunk.response.keywords[0].sentiment.score
      end
    end

    context "#words" do
      setup do
        @chunk = FactoryGirl.build(:chunk, :words)
      end

      should "get" do
        assert_equal Document::Response::WordCollection, @chunk.response.words.class
        assert_equal 50, @chunk.response.words.size
        # attributes
        assert_not_nil @chunk.response.words[0].i
        assert_not_nil @chunk.response.words[0].id
        assert_equal "This", @chunk.response.words[0].w
        assert_equal "This", @chunk.response.words[0].word
        assert_equal 1, @chunk.response.words[0].p
        assert_equal 1, @chunk.response.words[0].position
        assert_equal 0.7, @chunk.response.words[0].c
        assert_equal 0.7, @chunk.response.words[0].confidence
        assert_equal 1610.0, @chunk.response.words[0].s
        assert_equal 1610.0, @chunk.response.words[0].start_time
        assert_equal 1780.0, @chunk.response.words[0].e
        assert_equal 1780.0, @chunk.response.words[0].end_time
        # meta
        assert_equal ".", @chunk.response.words.last.word
        assert_equal "punc", @chunk.response.words.last.meta
      end

      should "#to_s" do
        sentence = "This is Tom Cook car team. This is a production. Verification video of a new feature. The future is direct video uploads to S three from Android devices. If this video upload successful even I believe this test is complete and the feature is verified."
        assert_equal sentence, @chunk.response.words.to_s
      end

      should "get #word aliases" do
        word = Document::Response::Word.new({id: "xyz", p: 1, s: 1.0, e: 2.0, w: "Hi!", c: 0.97, m: "punc"})
        assert_equal "xyz", word.id
        assert_equal 1, word.position
        assert_equal 1.0, word.start_time
        assert_equal 2.0, word.end_time
        assert_equal "Hi!", word.word
        assert_equal 0.97, word.confidence

        assert_equal word.i, word.id
        assert_equal word.p, word.position
        assert_equal word.s, word.start_time
        assert_equal word.e, word.end_time
        assert_equal word.w, word.word
        assert_equal word.c, word.confidence
      end

      should "set #word aliases" do
        word = Document::Response::Word.new({id: "xyz", p: 1, s: 1.0, e: 2.0, w: "Hi!", c: 0.97, m: "punc"})
        word.id = "abc"
        word.position = 2
        word.start_time = 5.0
        word.end_time = 6.0
        word.word = "Awesome!"
        word.confidence = 0.99

        assert_equal "abc", word.i
        assert_equal 2, word.p
        assert_equal 5.0, word.s
        assert_equal 6.0, word.e
        assert_equal "Awesome!", word.w
        assert_equal 0.99, word.c
      end
    end

    context "#speaker_segment" do
      setup do
        @chunk = FactoryGirl.build(:chunk, :speaker_segment)
      end

      should "get" do
        assert_equal Document::Response::SpeakerSegment, @chunk.response.speaker_segment.class
        assert_not_nil @chunk.response.speaker_segment
        assert_not_nil @chunk.response.speaker_segment.id
        assert_equal "M", @chunk.response.speaker_segment.gender
        assert_equal "U", @chunk.response.speaker_segment.bandwidth
        assert_equal "S0", @chunk.response.speaker_segment.speaker_id
        assert_equal "http://www.example.com/o/896d36d4/S0.gmm", @chunk.response.speaker_segment.speaker_model_uri
        assert_equal "-271324790387066728", @chunk.response.speaker_segment.speaker_supervector_hash
        assert_equal -31.339274605309463, @chunk.response.speaker_segment.speaker_mean_log_likelihood
        assert_equal 13.3100004196167, @chunk.response.speaker_segment.duration
        assert_equal 0.10999999940395355, @chunk.response.speaker_segment.start_time
        assert_equal 13.420000419020653, @chunk.response.speaker_segment.end_time
      end
    end
  end
end
