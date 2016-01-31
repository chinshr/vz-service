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
    should ensure_length_of(:title).is_at_most(255)

    should "validate presence of slug" do
      document = Document.new(:title => "this is a title")
      document.valid?
      assert_equal [], document.errors[:slug]

      document = Document.new
      document.valid?
      assert_equal [], document.errors[:slug]
    end
  end

  context "slug" do
    should "slug_id length" do
      document = FactoryGirl.create(:document)
      assert_equal 12, document.slug_id.length
    end

    should "generate valid slug with title and slug_id when re-publish" do
      document = Document.create(title: "this is a title", aasm_state: "published")
      assert_equal "this-is-a-title-#{document.slug_id}", document.slug
    end

    should "generate with title and slug_id when re-publishing with event=" do
      document = Document.create(title: "start-title", aasm_state: "published")
      assert_equal "start-title-#{document.slug_id}", document.slug
      document.event = :publish
      document.title  = "document-published-with-event"
      assert_equal true, document.save
      assert_equal "document-published-with-event-#{document.slug_id}", document.slug
    end

=begin
    should "generate with title and slug_id when re-publishing with status=" do
      document = Document.create(title: "start-title", aasm_state: "published")
      assert_equal "start-title-#{document.slug_id}", document.slug
      document.status = 1
      document.title  = "document-published-with-status"
      assert_equal true, document.save
      assert_equal "document-published-with-status-#{document.slug_id}", document.slug
    end
=end

    should "generate valid slug with only slug_id when unpublished" do
      document = Document.create(title: "this is a title", aasm_state: "unpublished")
      assert_equal "#{document.slug_id}", document.slug
    end

    should "generate new slug only when published and title has changed" do
      document = Document.create(title: "This is a Title", aasm_state: "published")
      stored_slug_id = document.slug_id
      assert_equal "this-is-a-title-#{document.slug_id}", document.slug
      document.attributes = {title: "When a man loves a woman!"}
      assert_equal true, document.publish!
      assert_equal "when-a-man-loves-a-woman-#{stored_slug_id}", document.slug
    end

    should "not generate new slug when title is changed but not recently published" do
      document = Document.create(title: "This is a Title", aasm_state: "published")
      stored_slug_id = document.slug_id
      assert_equal "this-is-a-title-#{document.slug_id}", document.slug
      document.update_attributes({title: "When a man loves a woman!"})
      assert_equal "When a man loves a woman!", document.reload.title
      assert_equal "this-is-a-title-#{document.slug_id}", document.slug
      assert_equal true, document.publish!
      assert_equal "when-a-man-loves-a-woman-#{stored_slug_id}", document.slug
    end

    should "find history" do
      document = Document.create(title: "This is a Title")
      stored_slug = document.slug
      assert Document.friendly.find(stored_slug)
      assert Document.friendly.exists?(stored_slug)
      document.update_attributes(title: "When a man loves a woman!")
      assert Document.friendly.find(stored_slug)
      assert Document.friendly.exists?(stored_slug)
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

    should "unpublish document when privacy private" do
      @document = FactoryGirl.create(:document, aasm_state: "published", privacy: ['public'], published_at: Time.zone.now - 1.day)
      assert_equal :published, @document.state
      assert_equal true, @document.privacy_public?
      @document.update_attributes(privacy: "private")
      assert_equal true, @document.privacy_private?
      assert_equal :unpublished, @document.state
    end
  end

  context "accessibility" do
    setup do
      @document = FactoryGirl.create(:document)
    end

    should "have accessibility" do
      assert_equal [], @document.accessibility
      @document.accessibility = :view
      assert_equal ["view"], @document.accessibility
      assert_equal true, @document.accessibility_viewable?

      @document.accessibility = :comment
      assert_equal ["comment"], @document.accessibility
      assert_equal true, @document.accessibility_commentable?

      @document.accessibility = :edit
      assert_equal ["edit"], @document.accessibility
      assert_equal true, @document.accessibility_editable?

      @document.accessibility = :foobar
      assert_equal [], @document.accessibility
    end

    should "be viewable" do
      @document.accessibility = :view
      assert_equal true, @document.accessibility_viewable?
      assert_equal false, @document.accessibility_commentable?
      assert_equal false, @document.accessibility_editable?
    end

    should "be commentable" do
      @document.accessibility = :comment
      assert_equal true, @document.accessibility_viewable?
      assert_equal true, @document.accessibility_commentable?
      assert_equal false, @document.accessibility_editable?
    end

    should "be editable" do
      @document.accessibility = :edit
      assert_equal true, @document.accessibility_viewable?
      assert_equal true, @document.accessibility_commentable?
      assert_equal true, @document.accessibility_editable?
    end
  end

  context "scopes" do
    setup do
      Document.destroy_all
    end

    should "have filtered scopes" do
      assert_equal [:sort_order, :reverse_sort, :is_root, :offset, :limit,
        :any_of_locales, :duration_lt, :duration_gt, :duration_lteq, :duration_gteq,
        :any_of_status, :none_of_status, :any_of_tags, :none_of_tags,
        :created_at_gt, :created_at_gteq, :created_at_lt, :created_at_lteq,
        :updated_at_gt, :updated_at_gteq, :updated_at_lt, :updated_at_lteq,
        :published_at_gt, :published_at_gteq, :published_at_lt, :published_at_lteq].to_set,
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

    should "#any_of_status" do
      d1 = FactoryGirl.create(:document, aasm_state: "published")
      d2 = FactoryGirl.create(:document, aasm_state: "unpublished")
      assert_equal [d1], Document.any_of_status([Document::STATE_PUBLISHED])
    end

    should "#none_of_status" do
      d1 = FactoryGirl.create(:document, aasm_state: "published")
      d2 = FactoryGirl.create(:document, aasm_state: "unpublished")
      assert_equal [d2], Document.none_of_status([Document::STATE_PUBLISHED])
    end

    should "#any_of_tags" do
      d1 = FactoryGirl.create(:document, tag_list: ["one", "two", "three"])
      d2 = FactoryGirl.create(:document, tag_list: ["four", "five", "six"])
      assert_equal d1, Document.any_of_tags("one").first
      assert_equal d2, Document.any_of_tags(["four", "five"]).first
    end

    should "#none_of_tags" do
      d1 = FactoryGirl.create(:document, tag_list: ["one", "two", "three"])
      d2 = FactoryGirl.create(:document, tag_list: ["four", "five", "six"])
      assert_equal d2, Document.none_of_tags(["one", "two", "three"]).first
    end

    context "#sort_order" do
      setup do
        @document1 = FactoryGirl.create(:document, published_at: Time.zone.now - 2.day)
        @document2 = FactoryGirl.create(:document, published_at: Time.zone.now - 1.day)
      end

      should "#id" do
        assert_equal @document2, Document.sort_order("id" => "desc").first
      end

      should "#published_at" do
        assert_equal @document2, Document.is_root(true).sort_order("published_at" => "desc").first
      end
    end

    context "date scopes" do
      setup do
        @document1 = FactoryGirl.create(:document, created_at: Time.zone.now - 2.day, updated_at: Time.zone.now - 2.day, published_at: Time.zone.now - 2.day)
        @document2 = FactoryGirl.create(:document, created_at: Time.zone.now - 1.day, updated_at: Time.zone.now - 1.day, published_at: Time.zone.now - 1.day)
      end

      should "#created_at_gt_and_gteq" do
        assert_equal @document2, Document.created_at_gt((Time.zone.now - 1.day).to_date.to_s).first
        assert_equal @document2, Document.created_at_gteq((Time.zone.now - 1.day).to_date.to_s).first
      end

      should "#created_at_lt_and_lteq" do
        assert_equal @document1, Document.created_at_lt((Time.zone.now - 1.day).to_date.to_s).first
        assert_equal @document1, Document.created_at_lteq((Time.zone.now - 1.day).to_date.to_s).first
      end

      should "#updated_at_gt_and_gteq" do
        assert_equal @document2, Document.updated_at_gt((Time.zone.now - 1.day).to_date.to_s).first
        assert_equal @document2, Document.updated_at_gteq((Time.zone.now - 1.day).to_date.to_s).first
      end

      should "#updated_at_lt_and_lteq" do
        assert_equal @document1, Document.updated_at_lt((Time.zone.now - 1.day).to_date.to_s).first
        assert_equal @document1, Document.updated_at_lteq((Time.zone.now - 1.day).to_date.to_s).first
      end

      should "#published_at_gt_and_gteq" do
        assert_equal @document2, Document.published_at_gt((Time.zone.now - 1.day).to_date.to_s).first
        assert_equal @document2, Document.published_at_gteq((Time.zone.now - 1.day).to_date.to_s).first
      end

      should "#published_at_lt_and_lteq" do
        assert_equal @document1, Document.published_at_lt((Time.zone.now - 1.day).to_date.to_s).first
        assert_equal @document1, Document.published_at_lteq((Time.zone.now - 1.day).to_date.to_s).first
      end
    end

  end

  context "document with ingests" do
    setup do
      @document = FactoryGirl.create(:document)
      @ingest   = FactoryGirl.create(:media_ingest_as_audio, :document => @document)
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
      @started = FactoryGirl.create(:media_ingest_as_audio, :document => @document, :aasm_state => "started")
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
    assert_enqueued_with(job: Track::DeleteJob) do
    # assert_difference "Track.count", 1 do
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
    c1 = Chunk::GoogleSpeechChunk.create(position: 1, offset: 0, text: "Das ist", score: 0.80, document: document)
    t1 = c1.create_track(s3_url: "http://t1", duration: 1.5)

    assert_nil document[:rich_text]
    assert_not_nil document.rich_text
    c1.start_time = 0.32
    c1.end_time   = 1.41
    c1.score      = 0.2
    rt = {"ops"=>[{"insert"=>"Das ist das", "attributes"=>{"segment" => c1.segment_id}}]}
    document.attributes = {"rich_text" => rt}
    document.save
    document = Document.find(document.id)
    assert_equal rt, document[:rich_text]
    assert_equal rt, document.rich_text
    assert_equal 0.32, c1.reload.start_time.to_f
    assert_equal 1.41, c1.reload.end_time.to_f
    assert_equal 1.0, c1.reload.score.to_f
    assert_equal "Das ist das", c1.reload.text
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

  context "meta helpers" do
    setup do
      @document = FactoryGirl.create(:document, title: "the title", description: "The description.",
        tag_list: ["one", "two", "three"])
    end

    should "#meta_title" do
      assert_equal "The Title",
        @document.meta_title
    end

    context "#meta_description" do

      should "not be longer than 200" do
        @document.description = "x" * 300
        assert_equal 200, @document.meta_description.length
        assert_equal "X" + "x" * 196 + "...", @document.meta_description
      end

      should "take first 200 characters from content" do
        @document.description = nil
        @document.html = "<p>the content</p>"
        assert_equal "The content", @document.meta_description
      end

      should "be same as #meta_title if description is empty" do
        @document.description = nil
        assert_equal nil, @document.meta_description
      end

    end

    should "#meta_keywords" do
      assert_equal "one,two,three", @document.meta_keywords
    end

    context "#published_url" do
      should "unset privacy should return nil" do
        assert_equal nil, @document.published_url
      end

      should "private unpublished should return nil" do
        @document.update_attributes(privacy: "private")
        assert_equal nil, @document.published_url
      end

      should "published should return published url" do
        @document.update_attributes(privacy: "limited", event: "publish")
        assert_equal "http://test/@#{@document.user.slug}/#{@document.slug}", @document.published_url
      end
    end

    context "#canonical_url" do
      should "unset privacy should return nil" do
        assert_equal nil, @document.canonical_url
      end

      should "private unpublished should return document url" do
        @document.update_attributes(privacy: "private")
        assert_equal "http://test/d/#{@document.slug_id}", @document.canonical_url
      end

      should "published should return published url" do
        @document.update_attributes(privacy: "limited", event: "publish")
        assert_equal "http://test/@#{@document.user.slug}/#{@document.slug}", @document.canonical_url
      end
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

  context "rich text" do
    setup do
      assert_difference "Segment::ChunkSegment.count", 3 do
        @document = FactoryGirl.create(:document)
        @t0 = @document.create_track(s3_url: "http://t0")

        @c1 = Chunk::GoogleSpeechChunk.create(:position => 1, :offset => 0, :text => "I hate to say", :score => 0.80, :document => @document)
        @t1 = @c1.create_track(s3_url: "http://t1", :duration => 10)
        @c2 = Chunk::GoogleSpeechChunk.create(:position => 2, :offset => 10, :text => "cat maths are", :score => 0.65, :document => @document)
        @t2 = @c2.create_track(s3_url: "http://t2", :duration => 10)
        @c3 = Chunk::GoogleSpeechChunk.create(:position => 3, :offset => 20, :text => "the cesty food in the world", :score => 0.85, :document => @document)
        @t3 = @c3.create_track(s3_url: "http://t3", :duration => 10)
      end
    end

    should "get rich_text sanity" do
      assert_equal "I hate to say", @document.rich_text['ops'][0]['insert']
      assert_equal [0.0, 10.0], Document.parse_segment_time(@document.rich_text['ops'][0]['attributes']['segment'])
      assert_equal 0.8, Document.parse_segment_score(@document.rich_text['ops'][0]['attributes']['segment'])

      assert_equal " ", @document.rich_text['ops'][1]['insert']

      assert_equal "cat maths are", @document.rich_text['ops'][2]['insert']
      assert_equal [10.0, 20.0], Document.parse_segment_time(@document.rich_text['ops'][2]['attributes']['segment'])
      assert_equal 0.65, Document.parse_segment_score(@document.rich_text['ops'][2]['attributes']['segment'])

      assert_equal " ", @document.rich_text['ops'][3]['insert']

      assert_equal "the cesty food in the world", @document.rich_text['ops'][4]['insert']
      assert_equal [20.0, 30.0], Document.parse_segment_time(@document.rich_text['ops'][4]['attributes']['segment'])
      assert_equal 0.85, Document.parse_segment_score(@document.rich_text['ops'][4]['attributes']['segment'])
    end

    should "set rich_text, text and score" do
      rt = @document.rich_text

      rt['ops'][2]['insert'] = "that cats make"
      rt['ops'][4]['insert'] = "the best food in the world."

      @document.rich_text = rt
      assert_equal true, @document.save
      @document = Document.find @document.id

      assert_equal "that cats make", @c2.reload.text
      assert_equal true, @c2.reload.score > 0.9
      assert_equal "the best food in the world.", @c3.reload.text
      assert_equal true, @c3.reload.score > 0.9
    end

    should "set rich_text, offset and duration" do
      c2_offset   = @c2.offset
      c2_duration = @c2.duration
      c3_offset   = @c3.offset
      c3_duration = @c3.duration

      rt = @document.rich_text
      rt['ops'][2]['attributes']['segment'] = @c2.uid + "+t2_30-7_30+s0_650"
      rt['ops'][4]['attributes']['segment'] = @c3.uid + "+t23_56-28_76+s0_850"

      @document.rich_text = rt
      assert_equal true, @document.save
      @document = Document.find @document.id

      assert_equal 2.3, @c2.reload.start_time
      assert_equal 7.3, @c2.reload.end_time
      assert_equal c2_offset, @c2.reload.offset, "remains unchanged"
      assert_equal c2_duration, @c2.reload.duration

      assert_equal 23.56, @c3.reload.start_time
      assert_equal 28.76, @c3.reload.end_time
      assert_equal c3_offset, @c3.reload.offset
      assert_equal c3_duration, @c3.reload.duration
    end
  end

  context "state machine" do
    should "have state and status" do
      document = FactoryGirl.create(:document)
      assert_equal :unpublished, document.state
      assert_equal 0, document.status
      assert_nil document.published_at
    end

    should "#publish! when unpublished public document" do
      document = FactoryGirl.create(:document, privacy: ['public'])
      assert_equal :unpublished, document.state
      assert_equal true, document.publish!
      assert_equal :published, document.state
      assert_equal 1, document.status
      assert_not_nil document.published_at
    end

    should "not #publish! when privacy private" do
      document = FactoryGirl.create(:document, privacy: ['private'])
      assert_equal true, document.privacy_private?
      assert_equal :unpublished, document.state
      assert_raise AASM::InvalidTransition do
        document.publish!
      end
      assert_equal :unpublished, document.state
    end

    should "#publish! when already published" do
      document = FactoryGirl.create(:document, aasm_state: "published", published_at: (ot = Time.zone.now - 1.day))
      assert_equal true, document.publish!
      assert_equal :published, document.state
      assert_not_equal ot, document.published_at
    end

    should "#unpublish! when published" do
      document = FactoryGirl.create(:document, aasm_state: "published", published_at: (ot = Time.zone.now - 1.day))
      assert_equal true, document.unpublish!
      assert_equal :unpublished, document.state
    end

    should "#unpublish! when already unpublished" do
      document = FactoryGirl.create(:document, aasm_state: "unpublished")
      assert_equal true, document.unpublish!
      assert_equal :unpublished, document.state
    end
  end

  should "#published_path" do
    document = FactoryGirl.create(:document)
    assert_equal "/@#{document.user.username}/#{document.slug}", document.published_path
  end

  context "words" do

    should "be initialized with empty array" do
      document = Document.new
      assert_equal [], document.words
    end

    should "set/get words as json" do
      words = [{"p"=>1,"c"=>0.7,"s"=>1.610,"e"=>1.780,"w"=>"This"},{"p"=>2,"c"=>0.714,"s"=>1.780,"e"=>1.960,"w"=>"is"}]
      document = FactoryGirl.create(:document, words: words)
      assert_equal words, document.reload.words
      assert_equal words.first, document.words.first
    end
  end

end
