require 'test_helper'

class Ingest::ResetJobTest < ActiveSupport::TestCase

  should "reset ingest after stopped" do
    ingest = FactoryGirl.create(:ingest_audio, aasm_state: "resetting", busy: false)
    Ingest::ResetJob.new.perform(ingest.id)
    ingest.reload
    assert_equal :reset, ingest.state
  end

  should "reschedule job when busy" do
    ingest = FactoryGirl.create(:ingest_audio, aasm_state: "resetting", busy: true)
    ActiveJob::ConfiguredJob.any_instance.expects(:perform_later).with(ingest.id, {retries: 4}).once
    Ingest::ResetJob.new.perform(ingest.id)
    ingest.reload
    assert_equal :resetting, ingest.state
  end

end