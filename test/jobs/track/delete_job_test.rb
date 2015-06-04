require 'test_helper'

class Track::DeleteJobTest < ActiveSupport::TestCase

  should "delete track" do
    track = FactoryGirl.create(:track)
    assert_difference "Track.count", -1 do
      Track::DeleteJob.new.perform(track.id)
    end
  end

end