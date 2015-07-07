require 'test_helper'

class DocumentTest < ActiveSupport::TestCase
  context "associations" do
    should belong_to :user
    should have_many :ingests
    should have_many(:segments).dependent(:destroy)
    should have_many(:child_segments).dependent(:destroy)
    should have_many(:chunks).through(:child_segments)
    should have_many(:tracks).through(:chunks)
    should have_many(:tracks_including_master_track).through(:segments)
    should have_one :master_document_segment
    should have_one(:track).through(:master_document_segment)

    should "have tracks_including_master_track" do
      assert_difference "Segment::DocumentSegment.count", 1 do
        assert_difference "Segment::ChunkSegment.count", 3 do
          @document = FactoryGirl.create(:document)
          @t0 = @document.create_track(s3_url: "http://t0")

          @c1 = Chunk::GoogleSpeechChunk.create(:position => 1, :offset => 0,  :text => "I hate to say", :score => 0.80, :document => @document)
          @t1 = @c1.create_track(s3_url: "http://t1")
          @c2 = Chunk::GoogleSpeechChunk.create(:position => 2, :offset => 10, :text => "cat maths are", :score => 0.65, :document => @document)
          @t2 = @c2.create_track(s3_url: "http://t2")
          @c3 = Chunk::GoogleSpeechChunk.create(:position => 3, :offset => 20, :text => "the cesty food in the world", :score => 0.85, :document => @document)
          @t3 = @c3.create_track(s3_url: "http://t3")

          assert_equal 3, @document.chunks.count
          assert_equal 3, @document.tracks.count
          assert_equal 4, @document.tracks_including_master_track.count
          assert_equal true, @document.master_segment.is_master?
          assert_equal [@t0.id, @t1.id, @t2.id, @t3.id].to_set,
            @document.tracks_including_master_track.map(&:id).to_set
          assert_equal @document.id, @t0.document.id
          assert_equal true, @c1.master_segment.is_master?
          assert_equal true, @c1.track.chunk_ids.include?(@c1.id)
          assert_equal true, @c1.master_segment.is_master?
          assert_equal true, @c2.master_segment.is_master?
          assert_equal true, @c3.track.chunks.include?(@c3)
          assert_equal true, @c3.master_segment.is_master?
        end
      end
    end

    should "accepts_nested_attributes_for :track" do
      assert_difference "Document.count", 1 do
        assert_difference "Segment::DocumentSegment.count", 1 do
          assert_difference "Track::DocumentTrack.count", 1 do
            document = Document.create(text: "test", title: "test",
              track_attributes: FactoryGirl.attributes_for(:track))
          end
        end
      end
    end
  end

  context "validations" do
    should validate_presence_of :title
    # should validate_presence_of :slug
    should ensure_length_of(:title).is_at_most(255)

    should "validate presence of slug" do
      document = Document.new(:slug => "test")
      document.valid?
      assert_not_equal "test", document.slug
      assert_equal [], document.errors[:slug]

      document = Document.new
      document.valid?
      assert_equal [], document.errors[:slug]
    end

    should "slug length" do
      document = FactoryGirl.create(:document)
      assert_equal 7, document.slug.length
    end
  end

  context "privacy mask" do
    should "set public" do
      @document = FactoryGirl.create(:document)

      @document.privacy = :public
      @document.save and @document = Document.find_by_id(@document.id)
      assert_equal ["public"], @document.privacy
      assert_equal true, @document.privacy_public?

      @document.privacy = "private"
      @document.save and @document = Document.find_by_id(@document.id)
      assert_equal ["private"], @document.privacy
      assert_equal true, @document.privacy_private?

      @document.privacy = "unlisted"
      @document.save and @document = Document.find_by_id(@document.id)
      assert_equal ["unlisted"], @document.privacy
      assert_equal true, @document.privacy_unlisted?
    end
  end

  context "scopes" do
    setup do
      Document.destroy_all
    end

    should "have filtered scopes" do
      assert_equal [:sort_order, :reverse_sort, :is_root, :offset, :limit,
        :any_of_locales, :duration_lt, :duration_gt, :duration_lteq, :duration_gteq].to_set,
        Document.scopes.to_set
    end

    should "#is_root" do
      @document1 = FactoryGirl.create(:document)
      @chunk1 = FactoryGirl.create(:chunk)
      assert_equal @document1, Document.is_root(true).sort_order("id" => "desc").last
      assert_equal @chunk1, Document.is_root(false).sort_order("id" => "desc").first
    end

    should "#recent" do
      @document1 = FactoryGirl.create(:document, :privacy => [:private])
      @document2 = FactoryGirl.create(:document, :privacy => [:public])
      assert_equal [@document2, @document1], Document.recent.to_a
      assert_equal [@document2, @document1], Document.recent(2).to_a
      assert_equal [@document2], Document.recent(1).to_a
    end

    should "#with_privacy" do
      @document1 = FactoryGirl.create(:document, :privacy => [:private])
      @document2 = FactoryGirl.create(:document, :privacy => [:public])
      assert_equal [@document1], Document.with_privacy(:private).to_a
      assert_equal [@document2], Document.with_privacy(:public).to_a
    end

    should "#with_user_privacy" do
      @user = FactoryGirl.create(:user)
      @document1 = FactoryGirl.create(:document, :privacy => [:private], :user => @user)
      @document2 = FactoryGirl.create(:document, :privacy => [:public])
      assert_equal [@document1, @document2], Document.with_user_privacy(@user).to_a
      assert_equal [@document2], Document.with_user_privacy(nil).to_a
    end

    should "#any_of_locales" do
      Document.destroy_all
      d1 = FactoryGirl.create(:document, locale: "en-GB")
      d2 = FactoryGirl.create(:document, locale: "en-US")
      d3 = FactoryGirl.create(:document, locale: "en-AU")
      d4 = FactoryGirl.create(:document, locale: "de-DE")
      assert_equal [d2], Document.any_of_locales("en-US")
      assert_equal [d2], Document.any_of_locales("en-us")
      assert_equal [d1, d2, d3], Document.any_of_locales("en")
      assert_equal [d4], Document.any_of_locales("de")
    end

  end

  context "document with ingests" do
    setup do
      @document = FactoryGirl.create(:document)
      @ingest   = FactoryGirl.create(:ingest_audio, :document => @document)
    end

    should "have finshed transcribing" do
      @ingest.update_attribute(:aasm_state, "finished")
      assert_equal true, @document.transcribed?
    end

    should "not have finshed transcribing" do
      @ingest.update_attribute(:aasm_state, "started")
      assert_equal false, @document.transcribed?
    end

    should "not have finshed transcribing with multiple ingests" do
      @started = FactoryGirl.create(:ingest_audio, :document => @document, :aasm_state => "started")
      @ingest.update_attribute(:aasm_state, "finished")
      assert_equal false, @document.transcribed?
    end
  end

  context "tags" do
    should "allow mixed case tags" do
      document = FactoryGirl.create(:document)
      document.tag_list = ["PoC", "myTest", "abra-kadabra"]
      document.save and document = Document.find(document.id)
      assert_equal ["PoC", "myTest", "abra-kadabra"], document.tag_list
    end

    should "not allow duplicate tags" do
      document = FactoryGirl.create(:document)
      document.tag_list = ["one", "one", "two"]
      document.save and document = Document.find(document.id)
      assert_equal ["one", "two"], document.tag_list
    end
  end

  should "#create_track and have one and only one master track" do
    @document = FactoryGirl.create(:document)
    assert_difference "Track.count", 1 do
      assert_difference "Segment.count", 1 do
        track = @document.create_track(s3_url: "http://foo/bar")
        assert_equal "http://foo/bar", @document.reload.track.s3_url
        assert_equal true, @document.master_segment.is_master?
        track = @document.create_track(s3_url: "http://one/two")
        assert_equal "http://one/two", @document.reload.track.s3_url
      end
    end
  end

  should "set/get content as rich_text array structure" do
    document = FactoryGirl.create(:document, rich_text: [])
    assert_equal [], document.rich_text
    hash = {"insert" => "Das ist", "attributes" => {"offset" => 0, "duration" => 1.2}}
    document.rich_text = [hash]
    document.save
    document = Document.find(document.id)
    assert_equal [hash], document.rich_text
  end

  should "set/get content as rich_text with attributes" do
    document = FactoryGirl.create(:document)
    array = [{"insert" => "Das ist", "attributes" => {"offset" => 0, "duration" => 1.2}}]
    document.attributes = {"rich_text" => array}
    document.save
    document = Document.find(document.id)
    assert_equal array, document.rich_text
  end

  should "set/get content as html" do
    document = FactoryGirl.create(:document, html: "Hello <b>World</b><i>!</i>")
    assert_equal "Hello <b>World</b><i>!</i>", document.html
  end

  should "set/get content as text" do
    document = FactoryGirl.create(:document, text: "Hello World!")
    assert_equal "Hello World!", document.text
  end

  should "have uid" do
    document = FactoryGirl.create(:document)
    assert_not_nil document.uid
    assert_equal 36, document.uid.length
  end

  should "be root?" do
    document = FactoryGirl.create(:document)
    assert_equal true, document.is_root?
    assert_equal true, document.is_root
  end

  context "parse segment" do
    setup do
      @segment = "37fc59fc-ac05-4a1f-9b72-b94f17f00f2d+t0_02-3_3+s0_75+crgba(45,23,89,0.2)+p123456"
    end

    should "parse uid" do
      assert_equal "37fc59fc-ac05-4a1f-9b72-b94f17f00f2d", Document.parse_segment_uid(@segment)
      assert_equal nil, Document.parse_segment_uid(nil)
    end

    should "parse time" do
      assert_equal [0.02, 3.3], Document.parse_segment_time(@segment)
      assert_equal [1.0, 2.0], Document.parse_segment_time("37f+t1-2")
      assert_equal nil, Document.parse_segment_time("no-time")
    end

    should "parse score" do
      assert_equal 0.75, Document.parse_segment_score(@segment)
      assert_equal 0.33, Document.parse_segment_score("37f+t0_02-3_3+s0_33")
      assert_equal nil, Document.parse_segment_score("no-score#aaa")
    end

    should "parse profile" do
      assert_equal "123456", Document.parse_segment_profile(@segment)
      assert_equal "abcdef", Document.parse_segment_profile("123+pabcdef+cccc")
      assert_equal nil, Document.parse_segment_profile("no-profile+caaa+t1-2")
    end

    should "parse color" do
      assert_equal "rgba(45,23,89,0.2)", Document.parse_segment_color(@segment)
      assert_equal "rgba(45,23,89,0.2)", Document.parse_segment_color("37f+t0_02-3_3+s0_75+crgba(45,23,89,0.2)")
      assert_equal "ccc", Document.parse_segment_color("37f+t0_02-3_3+s0_75+cccc")
      assert_equal nil, Document.parse_segment_color("no-color^1-2")
    end
  end

  should "have versions" do
    document = FactoryGirl.create(:document, title: "Title", description: "Desc",
      html: "<p>The article.</p>", text: "The article.", rich_text: {"ops" => [{"insert" => "The article."}]})
    assert_equal 1, document.versions.size
    document.rich_text = {"ops" => [{"insert" => "The article."}, {"insert" => "What a beauty."}]}
    document.save
    assert_equal 2, document.versions.size
    assert_equal({"ops" => [{"insert" => "The article."}]}, document.previous_version.rich_text)
  end
end
