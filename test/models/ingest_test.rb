require 'test_helper'

class IngestTest < ActiveSupport::TestCase
  context "associations" do
    should belong_to :upload
    should belong_to :ingestable
  end

  context "validations" do
    should validate_presence_of :upload
    should validate_presence_of :ingestable
  end
  
  should "have status" do
    ingest = FactoryGirl.create(:ingest_audio)
    assert_equal :created, ingest.aasm_current_state
    assert_equal 0, ingest.status
  end
  
  should "work with state machine" do
    ingest = FactoryGirl.create(:ingest_audio)
    assert_equal :created, ingest.aasm_current_state

    ingest.start!
    assert_equal :starting, ingest.aasm_current_state
    ingest.process!
    assert_equal :started, ingest.aasm_current_state
    assert_not_nil ingest.started_at

    ingest.stop!
    assert_equal :stopping, ingest.aasm_current_state
    ingest.process!
    assert_equal :stopped, ingest.aasm_current_state
    assert_not_nil ingest.stopped_at

    ingest.start!
    assert_equal :starting, ingest.aasm_current_state
    ingest.process!
    assert_equal :started, ingest.aasm_current_state
    assert_not_nil ingest.started_at

    ingest.stop!
    assert_equal :stopping, ingest.aasm_current_state
    ingest.process!
    assert_equal :stopped, ingest.aasm_current_state
    assert_not_nil ingest.stopped_at

    ingest.reset!
    assert_equal :resetting, ingest.aasm_current_state
    ingest.process!
    assert_equal :reset, ingest.aasm_current_state
    assert_not_nil ingest.reset_at
    assert_equal 1, ingest.iteration

    ingest.start!
    assert_equal :starting, ingest.aasm_current_state
    ingest.process!
    assert_equal :started, ingest.aasm_current_state
    assert_not_nil ingest.started_at

    ingest.finish!
    assert_equal :finished, ingest.aasm_current_state
    assert_not_nil ingest.finished_at

    ingest.remove!
    assert_equal :removing, ingest.aasm_current_state
    ingest.process!
    assert_equal :removed, ingest.aasm_current_state
    assert_not_nil ingest.removed_at
  end
  
  should "log message" do
    ingest = FactoryGirl.create(:ingest_audio)
    ingest.log! :copy, "File not found."
    assert_equal ["File not found."], ingest.messages["copy"]
    ingest.log! :transcode, "Service unavailable."
    assert_equal ["Service unavailable."], ingest.messages["transcode"]
    ingest.log! 'transcode', "Unsufficient disk space."
    assert_equal ["Service unavailable.", "Unsufficient disk space."], ingest.messages["transcode"]
  end
  
  should "delegate to @upload#s3_key" do
    ingest = FactoryGirl.create(:ingest_audio)
    assert_not_nil ingest.s3_key
  end

  should "delegate to @upload#s3_url" do
    ingest = FactoryGirl.create(:ingest_audio)
    assert_not_nil ingest.s3_url
  end
end
