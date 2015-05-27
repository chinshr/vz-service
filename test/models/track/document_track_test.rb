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

  context "delegate" do
    setup do
      @track = FactoryGirl.create(:track_with_document_and_ingest)
      @track.document.update_attributes(duration: 1234,
        start_at: Time.zone.now - 2.days, end_at: Time.zone.now - 1.days)
    end
=begin
    should "#duration" do
      assert_equal @track.document.duration, @track.duration
      assert_not_nil @track.duration
    end

    should "#start_at" do
      assert_equal @track.document.start_at, @track.start_at
      assert_not_nil @track.start_at
    end

    should "#end_at" do
      assert_equal @track.document.end_at, @track.end_at
      assert_not_nil @track.end_at
    end
=end

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