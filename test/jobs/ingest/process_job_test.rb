require 'test_helper'

class Ingest::ProcessJobTest < ActiveSupport::TestCase

  should "stop ingest after stopping" do
    ingest = FactoryGirl.create(:media_ingest_as_audio, aasm_state: "stopping", busy: false)
    Ingest::ProcessJob.new.perform(ingest.id)
    ingest.reload
    assert_equal :stopped, ingest.state
  end

  should "remove ingest after removing" do
    ingest = FactoryGirl.create(:media_ingest_as_audio, aasm_state: "removing", busy: false)
    Ingest::ProcessJob.new.perform(ingest.id)
    ingest.reload
    assert_equal :removed, ingest.state
  end

  should "reset ingest after resetting" do
    ingest = FactoryGirl.create(:media_ingest_as_audio, aasm_state: "resetting", busy: false)
    Ingest::ProcessJob.new.perform(ingest.id)
    ingest.reload
    assert_equal :reset, ingest.state
  end

  should "reschedule job when busy" do
    ingest = FactoryGirl.create(:media_ingest_as_audio, aasm_state: "resetting", busy: true)
    ActiveJob::ConfiguredJob.any_instance.expects(:perform_later).with(ingest.id, {retries: 4}).once
    Ingest::ProcessJob.new.perform(ingest.id)
    ingest.reload
    assert_equal :resetting, ingest.state
  end

end