require 'test_helper'

class Track::ChunkTrackTest < ActiveSupport::TestCase
  context "associations" do
    should have_many(:chunk_segments).dependent(:nullify)
    should have_many(:chunks).through(:chunk_segments)

    should "have ingest integrity" do
      track = FactoryGirl.create(:track_with_chunk_and_ingest).reload
      assert_equal false, track.is_master?
      assert_equal true, track.segments.map(&:track_id).include?(track.id)
      assert_equal true, track.chunk_segments.map(&:track_id).include?(track.id)
      assert_equal "Segment::ChunkSegment", track.chunk_segments.first.class.name
    end
  end

end