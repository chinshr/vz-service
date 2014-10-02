require 'test_helper'

class Ingest::AudioWorkerTest < ActiveSupport::TestCase
  
  setup do
    Ingest::AudioWorker.any_instance.stubs(:remove_all_s3_objects).returns(true)
    
    @ingest = FactoryGirl.create(:ingest_audio)
    @track  = @ingest.create_track(:s3_url => "http://s3.amazonaws.com/private/zp66vfwg21-1")
    
    Ingest::AudioWorker.jobs.clear
  end

  should "destroy" do
    @ingest.remove!
    assert_equal :removing, @ingest.state

    assert_difference "Ingest.count", -1 do
      worker = Ingest::RemoveWorker.new
      worker.perform(@ingest.id)
    end
  end

  should "not destroy if ingest is not removing" do
    assert_equal :created, @ingest.state
    assert_no_difference "Ingest.count" do
      Ingest::RemoveWorker.new.perform(@ingest.id)
    end
  end

end
