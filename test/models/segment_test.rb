require 'test_helper'

class SegmentTest < ActiveSupport::TestCase
  context "associations" do
    should belong_to :document
    should belong_to :track
    should belong_to :ingest
    should belong_to :chunk
  end

  context "#destroy" do
    setup do
      @segment = FactoryGirl.create(:segment)
    end

    should "be paranoid" do
      assert_difference "Segment.count", -1 do
        @segment.destroy
        assert_not_nil @segment.deleted_at
      end
    end

    should "if last track" do
      assert_enqueued_with(job: Track::DeleteJob) do
        @segment.destroy
      end
    end

    should "not destroy track if other segments with same track" do
      segment1 = FactoryGirl.create(:segment)
      segment2 = FactoryGirl.create(:segment, track: segment1.track)
      assert_difference "Segment.count", -1 do
        assert_no_difference "Track.count" do
          segment2.destroy
        end
      end
    end
  end
end
