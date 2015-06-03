require 'test_helper'

class SegmentTest < ActiveSupport::TestCase
  context "associations" do
    should belong_to :document
    should belong_to :track
    should belong_to :ingest
    should belong_to :chunk
  end

  context "destroy" do
    should "if last track" do
      segment = FactoryGirl.create(:segment)
      assert_difference "Segment.count", -1 do
        assert_difference "Track.count", -1 do
          segment.destroy
        end
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
