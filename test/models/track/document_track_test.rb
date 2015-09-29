require 'test_helper'

class Track::DocumentTrackTest < ActiveSupport::TestCase
  context "associations" do
    should have_one(:document_segment).dependent(:nullify)
    should have_one(:ingest).through(:document_segment).source(:ingest)
    should have_one(:document).through(:document_segment).source(:document)

    should "have ingest integrity" do
      track = FactoryGirl.create(:track_with_document_and_ingest)
      assert_equal track.document.ingests.first, track.ingest
      assert_equal track.id, track.document_segment.track_id
      assert_equal track.document.id, track.document_segment.document_id
      assert_equal track.document.ingests.first.id, track.document_segment.ingest_id
    end
  end

  should "create document master track" do
    ingest = FactoryGirl.create(:ingest_audio)
    assert_equal 1, ingest.document.track.segments.count
    assert_no_difference "Track::DocumentTrack.count" do
      assert_no_difference "Segment::DocumentSegment.count" do
        track = nil
        assert_enqueued_with(job: Track::DeleteJob) do
          track = Track.create({
            type: "document_track",
            ingest: ingest,
            s3_url: "http://s3.amazonaws.com/vz-test-origin/13dba008-7ba2-4804-a534-43d03c65260b/t0",
            ingest_iteration: ingest.iteration
          })
          assert_equal true, track.document_segment.is_master?
        end
        Track::DeleteJob.new.perform(track.id)
      end
    end
  end

  context "delegate" do
    setup do
      @track = FactoryGirl.create(:track_with_document_and_ingest)
    end

    should "#ingest_id to document_segment" do
      assert_equal @track.document_segment.ingest_id, @track.ingest_id
      assert_not_nil @track.ingest_id
    end

    should "#document_id to segment" do
      assert_equal @track.document_segment.document_id, @track.document_id
      assert_not_nil @track.document_id
    end
  end
end