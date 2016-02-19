require 'test_helper'

class Track::DeleteJobTest < ActiveSupport::TestCase

  setup do
    @track = FactoryGirl.create(:track)
  end

  should "delete track" do
    assert_difference "Track.count", -1 do
      Track::DeleteJob.new.perform(@track.id)
    end
  end

  should "delete already destroyed track" do
    @track.destroy
    assert_difference "Track.with_deleted.count", -1 do
      Track::DeleteJob.new.perform(@track.id)
    end
  end

end