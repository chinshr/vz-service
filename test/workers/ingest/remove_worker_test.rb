require 'test_helper'

class Ingest::AudioWorkerTest < ActiveSupport::TestCase
  setup do
    Ingest::AudioWorker.any_instance.stubs(:remove_all_s3_objects).returns(true)

    @ingest = FactoryGirl.create(:ingest_audio)

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

end
