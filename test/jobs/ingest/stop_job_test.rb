require 'test_helper'

class Ingest::StopJobTest < ActiveSupport::TestCase

  should "stop running ingest when not busy" do
    ingest = FactoryGirl.create(:media_ingest_as_audio, aasm_state: "stopping", busy: false)
    Ingest::StopJob.new.perform(ingest.id)
    ingest.reload
    assert_equal :stopped, ingest.state
  end

  should "reschedule job when busy" do
    ingest = FactoryGirl.create(:media_ingest_as_audio, aasm_state: "stopping", busy: true)
    ActiveJob::ConfiguredJob.any_instance.expects(:perform_later).with(ingest.id, {retries: 4}).once
    Ingest::StopJob.new.perform(ingest.id)
    ingest.reload
    assert_equal :stopping, ingest.state
  end

  should "#stop all running workers" do
    ingest = FactoryGirl.create(:media_ingest_as_audio,
      aasm_state: "stopping", aasm_stage: "split_stage",
      busy: true, terminate: false)
    w1 = FactoryGirl.create(:ingest_worker, :finished, worker_name: "ingest/media_ingest/harvest_worker", ingest: ingest)
    w2 = FactoryGirl.create(:ingest_worker, :finished, worker_name: "ingest/media_ingest/transcode_worker", ingest: ingest)
    w3 = FactoryGirl.create(:ingest_worker, :created, worker_name: "ingest/media_ingest/split_worker", ingest: ingest)
    Ingest::StopJob.new.perform(ingest.id)
    assert_equal true, w1.reload.finished?
    assert_equal true, w2.reload.finished?
    assert_equal true, w3.reload.stopped?
  end


end