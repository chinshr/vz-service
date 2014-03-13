require 'test_helper'

class TrackTest < ActiveSupport::TestCase
  context "validations" do
    should validate_presence_of :s3_url
  end
  
  should "have a document" do
    ingest = FactoryGirl.create(:ingest_audio)
    track  = ingest.create_track(:s3_url => "http://s3.amazonaws.com/private/zp66vfwg21-1")
    assert_equal true, track.valid?
    assert_equal true, ingest.save
    track.reload
    assert_equal ingest, track.ingest
    assert_equal ingest.ingestable, track.document
  end
   
end
