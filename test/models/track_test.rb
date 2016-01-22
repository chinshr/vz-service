require 'test_helper'

class TrackTest < ActiveSupport::TestCase
  context "build" do
    should "#create document track" do
      @ingest = FactoryGirl.create(:media_ingest_as_audio)
      assert_no_difference "Segment::DocumentSegment.count" do
        track = Track::DocumentTrack.create({
          ingest: @ingest,
          s3_url: "http://aws.amazon.com/foo/master",
          ingest_iteration: 0
        })
        assert_equal false, track.new_record?
        assert_equal true, track.is_a?(Track::DocumentTrack)
        #assert_equal true, track.is_master?
        assert_equal 0, track.ingest_iteration
        assert_equal @ingest, track.ingest
        assert_equal @ingest.document, track.document
      end
    end

    should "#create chunk track" do
      @chunk = FactoryGirl.create(:chunk)
      assert_difference "Segment::ChunkSegment.count", 1 do
        track = Track::ChunkTrack.create({
          chunk_ids: [@chunk.id],
          s3_url: "http://aws.amazon.com/foo/master",
          ingest_iteration: 0
        })
        assert_equal false, track.new_record?
        assert_equal true, track.is_a?(Track::ChunkTrack)
        #assert_equal false, track.is_master?
        assert_equal 0, track.ingest_iteration
        assert_equal true, track.chunks.include?(@chunk)
        assert_equal @chunk.id, track.chunk_ids.first
      end
    end
  end

  context "associations" do
    should have_many(:segments).dependent(:nullify)
  end

  context "scopes" do
    setup do
      @track1 = FactoryGirl.create(:master_track)
      @track2 = FactoryGirl.create(:track)
    end

    should "have filtered scopes" do
      assert_equal [:sort_order, :reverse_sort, :offset, :limit, :any_of_types, :none_of_types].to_set,
        Track.scopes.to_set
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

    context "Class#s3_url_to_key" do
      should "return key with valid URL" do
        key = Track.s3_url_to_key("http://s3.amazonaws.com/vz-dev-origin/320cadee-e9b7-4c50-9595-80a11ac12780/km5dliv3rq")
        assert_equal "320cadee-e9b7-4c50-9595-80a11ac12780/km5dliv3rq", key
      end

      should "return nil with nil URL" do
        assert_equal nil, Track.s3_url_to_key(nil)
      end
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
      assert_equal "vz-test-origin", @track.send(:s3_origin_bucket_name)
    end

    should "#s3_waveform_json_key" do
      assert_equal "13dba008-7ba2-4804-a534-43d03c65260b/gzgtnh1iui.ac2.waveform.json", @track.s3_waveform_json_key
    end

    should "#waveform_json_stream_url" do
      assert_equal true, @track.waveform_json_stream_url.include?("s3.amazonaws.com")
      assert_equal true, @track.waveform_json_stream_url.include?(@track.s3_waveform_json_key)
    end
  end

  should "destroy with job" do
    track = FactoryGirl.create(:track)
    assert_enqueued_with(job: Track::DeleteJob) do
      track.destroy
    end
  end
end
