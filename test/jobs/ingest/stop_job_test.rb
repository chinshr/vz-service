require 'test_helper'

class Ingest::StopJobTest < ActiveSupport::TestCase

  should "stop running ingest when not busy" do
    ingest = FactoryGirl.create(:ingest_audio, aasm_state: "stopping", busy: false)
    Ingest::StopJob.new.perform(ingest.id)
    ingest.reload
    assert_equal :stopped, ingest.state
  end

  should "reschedule job when busy" do
    ingest = FactoryGirl.create(:ingest_audio, aasm_state: "stopping", busy: true)
    ActiveJob::ConfiguredJob.any_instance.expects(:perform_later).with(ingest.id, {retries: 4}).once
    Ingest::StopJob.new.perform(ingest.id)
    ingest.reload
    assert_equal :stopping, ingest.state
  end

end