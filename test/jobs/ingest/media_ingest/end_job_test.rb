require 'test_helper'

class Ingest::MediaIngest::EndJobTest < ActiveSupport::TestCase

  should "forward ingest to end_stage" do
    ingest = FactoryGirl.create(:ingest_audio, aasm_state: "started", aasm_stage: "archive_stage")
    Ingest::MediaIngest::EndJob.new.perform(ingest.id)
    ingest.reload
    assert_equal :end_stage, ingest.stage
    assert_equal 100, ingest.progress
    assert_equal :finished, ingest.state
  end

end