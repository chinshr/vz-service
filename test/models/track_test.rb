require 'test_helper'

class TrackTest < ActiveSupport::TestCase
  context "associations" do
    should have_one(:tracking).dependent(:destroy)
    should have_one(:document).through(:tracking).source(:document)
    should have_one(:ingest).through(:tracking).source(:ingest)
    # should have_many(:ingests).through(:document).source(:ingests)

    should "have_many :ingests through :document" do
      skip "not used"
      @ingest = FactoryGirl.create(:ingest_audio)
      assert_equal @ingest, @ingest.track.ingests.first
    end

    should "chunk track have ingest integrity" do
      track = FactoryGirl.create(:track_with_chunk_and_ingest)
      assert_equal track.document.ingest, track.ingest
      assert_equal track.id, track.tracking.track_id
      assert_equal track.document.id, track.tracking.document_id
      assert_equal track.document.ingest.id, track.tracking.ingest_id
    end

    should "document track have ingest integrity" do
      track = FactoryGirl.create(:track_with_document_and_ingest)
      assert_equal track.document.ingests.first, track.ingest
      assert_equal track.id, track.tracking.track_id
      assert_equal track.document.id, track.tracking.document_id
      assert_equal track.document.ingests.first.id, track.tracking.ingest_id
    end
  end

  context "validations" do
    should validate_presence_of :s3_url
  end

  context "scopes" do
    setup do
      @track1 = FactoryGirl.create(:master_track)
      @track2 = FactoryGirl.create(:track)
    end

    should "have filtered scopes" do
      assert_equal [:sort_order, :reverse_sort, :is_master, :offset, :limit].to_set,
        Track.scopes.to_set
    end

    should "#is_master" do
      assert_equal [@track1], Track.is_master(1)
      assert_equal [@track1], Track.is_master("true")
      assert_equal [@track1], Track.filter("is_master" => "1")
      assert_equal [@track2], Track.filter("is_master" => "false")
    end
  end

  should "have s3_key" do
    track = FactoryGirl.create(:track, :s3_url => "http://s3.amazonaws.com/private/zp66vfwg",
      :s3_mp3_url => "http://s3.amazonaws.com/private/zp66vfwg.128.mp3")
    assert_equal "zp66vfwg", track.s3_key
  end

  should "have s3_uri" do
    track = FactoryGirl.create(:track, :s3_url => "http://s3.amazonaws.com/vz-dev-origin/13dba008-7ba2-4804-a534-43d03c65260b/gzgtnh1iui",
      :s3_mp3_url => "http://s3.amazonaws.com/vz-dev-origin/13dba008-7ba2-4804-a534-43d03c65260b/gzgtnh1iui.128.mp3")
    assert_equal "13dba008-7ba2-4804-a534-43d03c65260b/gzgtnh1iui", track.s3_uri
    track.s3_url = nil
    assert_nil track.s3_uri
  end

  should "have s3_mp3_key" do
    track = FactoryGirl.create(:track, :s3_url => "http://s3.amazonaws.com/private/zp66vfwg",
      :s3_mp3_url => "http://s3.amazonaws.com/private/zp66vfwg.128.mp3")
    assert_equal "zp66vfwg.128.mp3", track.s3_mp3_key
  end

  should "get mp3_stream_url" do
    track = FactoryGirl.create(:track, :s3_url => "http://s3.amazonaws.com/private/zp66vfwg",
      :s3_mp3_url => "http://s3.amazonaws.com/private/zp66vfwg.128.mp3")
    assert_equal true, track.mp3_stream_url.include?("s3.amazonaws.com")
    assert_equal true, track.mp3_stream_url.include?(track.s3_mp3_key)
  end

  should "have uid" do
    track = FactoryGirl.create(:track)
    assert_not_nil track.uid
    assert_equal 36, track.uid.length
  end

end
