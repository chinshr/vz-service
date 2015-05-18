require 'test_helper'

class TrackTest < ActiveSupport::TestCase
  context "associations" do
    should have_one(:tracking).dependent(:destroy)
    should have_one(:document).through(:tracking).source(:document)
    should have_one(:ingest).through(:tracking).source(:ingest)

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

  context "delegate" do
    setup do
      @track = FactoryGirl.create(:track_with_chunk_and_ingest)
    end

    should "ingest_id to trackings.ingest_id" do
      assert_equal @track.tracking.ingest_id, @track.ingest_id
    end

    should "document_id to trackings.document_id" do
      assert_equal @track.tracking.document_id, @track.document_id
    end

    should "offset to document.offset" do
      assert_equal true, @track.document.is_a?(Chunk)
      assert_equal @track.document.offset, @track.offset
    end

    should "duration to document.duration" do
      assert_equal @track.document.duration, @track.duration
    end

    should "start_at to document.start_at" do
      assert_equal @track.document.start_at, @track.start_at
    end

    should "end_at to document.end_at" do
      assert_equal @track.document.end_at, @track.end_at
    end
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

  should "have uid" do
    track = FactoryGirl.create(:track)
    assert_not_nil track.uid
    assert_equal 36, track.uid.length
  end

  context "helpers" do
    setup do
      @track = FactoryGirl.create(:track,
        s3_url: "http://s3.amazonaws.com/vz-dev-origin/13dba008-7ba2-4804-a534-43d03c65260b/gzgtnh1iui",
        s3_mp3_url: "http://s3.amazonaws.com/vz-dev-origin/13dba008-7ba2-4804-a534-43d03c65260b/gzgtnh1iui.128.mp3",
        s3_waveform_json_url: "http://s3.amazonaws.com/vz-dev-origin/13dba008-7ba2-4804-a534-43d03c65260b/gzgtnh1iui.ac2.waveform.json")
    end

    should "#s3_key" do
      assert_equal "13dba008-7ba2-4804-a534-43d03c65260b/gzgtnh1iui", @track.s3_key
      @track.s3_url = "http://s3.amazonaws.com/vz-dev-origin/gzgtnh1iui"
      assert_equal "gzgtnh1iui", @track.s3_key
    end

    should "#s3_mp3_key" do
      assert_equal "13dba008-7ba2-4804-a534-43d03c65260b/gzgtnh1iui.128.mp3", @track.s3_mp3_key
    end

    should "#mp3_stream_url" do
      assert_equal true, @track.mp3_stream_url.include?("s3.amazonaws.com")
      assert_equal true, @track.mp3_stream_url.include?(@track.s3_mp3_key)
    end

    should "#s3_origin_bucket_name" do
      assert_equal "vz-dev-origin", @track.send(:s3_origin_bucket_name)
    end

    should "#s3_waveform_json_key" do
      assert_equal "13dba008-7ba2-4804-a534-43d03c65260b/gzgtnh1iui.ac2.waveform.json", @track.s3_waveform_json_key
    end

    should "#waveform_json_stream_url" do
      assert_equal true, @track.waveform_json_stream_url.include?("s3.amazonaws.com")
      assert_equal true, @track.waveform_json_stream_url.include?(@track.s3_waveform_json_key)
    end

  end

end
