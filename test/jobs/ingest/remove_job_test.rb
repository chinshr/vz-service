require 'test_helper'

class Ingest::RemoveJobTest < ActiveSupport::TestCase

  should "remove ingest" do
    ingest = FactoryGirl.create(:ingest_audio, aasm_state: "removing")
    Ingest::RemoveJob.new.perform(ingest.id)
    ingest.reload
    assert_equal :removed, ingest.state
  end

  should "reschedule job when busy" do
    ingest = FactoryGirl.create(:ingest_audio, aasm_state: "removing", busy: true)
    ActiveJob::ConfiguredJob.any_instance.expects(:perform_later).with(ingest.id, {retries: 4}).once
    Ingest::RemoveJob.new.perform(ingest.id)
    ingest.reload
    assert_equal :removing, ingest.state
  end

end