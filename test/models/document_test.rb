require 'test_helper'

class DocumentTest < ActiveSupport::TestCase
  context "associations" do
    should have_many :ingests
    should have_many :chunks
    should have_many :tracks
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
    should "recent" do
      @document1 = FactoryGirl.create(:document, :privacy => [:private])
      @document2 = FactoryGirl.create(:document, :privacy => [:public])
      assert_equal [@document2, @document1], Document.recent.to_a
      assert_equal [@document2, @document1], Document.recent(2).to_a
      assert_equal [@document2], Document.recent(1).to_a
    end

    should "with_privacy" do
      @document1 = FactoryGirl.create(:document, :privacy => [:private])
      @document2 = FactoryGirl.create(:document, :privacy => [:public])
      assert_equal [@document1], Document.with_privacy(:private).to_a
      assert_equal [@document2], Document.with_privacy(:public).to_a
    end

    should "with_user_privacy" do
      @user = FactoryGirl.create(:user)
      @document1 = FactoryGirl.create(:document, :privacy => [:private], :user => @user)
      @document2 = FactoryGirl.create(:document, :privacy => [:public])
      assert_equal [@document1, @document2], Document.with_user_privacy(@user).to_a
      assert_equal [@document2], Document.with_user_privacy(nil).to_a
    end
  end

  context "document with ingests" do
    setup do
      @document = FactoryGirl.create(:document)
      @ingest   = FactoryGirl.create(:ingest_audio, :ingestable => @document)
    end

    should "have finshed transcribing" do
      @ingest.update_attribute(:aasm_state, "finished")
      assert_equal true, @document.trancribed?
    end

    should "not have finshed transcribing" do
      @ingest.update_attribute(:aasm_state, "started")
      assert_equal false, @document.trancribed?
    end

    should "not have finshed transcribing with multiple ingests" do
      @started = FactoryGirl.create(:ingest_audio, :ingestable => @document, :aasm_state => "started")
      @ingest.update_attribute(:aasm_state, "finished")
      assert_equal false, @document.trancribed?
    end
  end

  should "calculate average score and duration" do
    document = FactoryGirl.create(:document)
    chunk1 = FactoryGirl.create(:document_chunk, :offset => 0, :document => document, :score => 0)
    chunk2 = FactoryGirl.create(:document_chunk, :offset => 1, :document => document, :score => 0.5)
    chunk3 = FactoryGirl.create(:document_chunk, :offset => 2, :document => document, :score => 1)
    assert_equal 3, document.chunks.count
    assert_equal 0.5, document.score.to_f
    assert_equal 10.53, document.duration.to_f
  end

  should "order chunks by offset" do
    document = FactoryGirl.create(:document)
    chunk3 = FactoryGirl.create(:document_chunk, :offset => 2, :document => document, :score => 1)
    chunk1 = FactoryGirl.create(:document_chunk, :offset => 0, :document => document, :score => 0)
    chunk2 = FactoryGirl.create(:document_chunk, :offset => 1, :document => document, :score => 0.5)
    assert_equal 3, document.chunks.count
    chunks = document.chunks.order(:offset)
    assert_equal chunk1, chunks[0]
    assert_equal chunk2, chunks[1]
    assert_equal chunk3, chunks[2]
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

  should "have a track" do
    @document = FactoryGirl.create(:document)
    @track1    = FactoryGirl.create(:track)
    @ingest1   = FactoryGirl.create(:ingest_audio, :ingestable => @document, :track_id => @track1.id)
    @track2    = FactoryGirl.create(:track)
    @ingest2   = FactoryGirl.create(:ingest_audio, :ingestable => @document, :track_id => @track2.id)
    assert_equal @track2, @document.track
  end

end
