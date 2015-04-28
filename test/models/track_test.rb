require 'test_helper'

class TrackTest < ActiveSupport::TestCase
  context "validations" do
    should validate_presence_of :s3_url
  end

  context "associations" do
    should belong_to :document
    should have_many(:ingests).through(:document).source(:ingests)

    should "have_many :ingests through :document" do
      @ingest = FactoryGirl.create(:ingest_audio)
      assert_equal @ingest, @ingest.track.ingests.first
    end
  end

  should "get s3_key" do
    track = FactoryGirl.create(:track, :s3_url => "http://s3.amazonaws.com/private/zp66vfwg",
      :s3_mp3_url => "http://s3.amazonaws.com/private/zp66vfwg.128.mp3")
    assert_equal "zp66vfwg", track.s3_key
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
