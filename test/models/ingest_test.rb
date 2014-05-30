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
    assert_equal :created, ingest.state
    assert_equal 0, ingest.status
  end
  
  should "work with state machine" do
    ingest = FactoryGirl.create(:ingest_audio, :terminate => true, :busy => true)
    assert_equal :created, ingest.state

    ingest.start!
    assert_equal :starting, ingest.state
    assert_equal false, ingest.terminate?
    assert_equal false, ingest.busy?
    ingest.process!
    assert_equal :started, ingest.state
    assert_not_nil ingest.started_at
    ingest.log! :started, "working"
    ingest.update_attributes(stage: "transcoding")
    FactoryGirl.create(:document_chunk, :document => ingest.ingestable)
    assert_equal 0, ingest.iteration
    assert_equal false, ingest.messages.empty?

    ingest.clear_terminate!
    assert_equal false, ingest.terminate?
    ingest.restart!
    assert_equal :restarting, ingest.state
    assert_equal true, ingest.terminate?
    assert_equal false, ingest.messages.empty?
    ingest.process!
    assert_equal :started, ingest.state
    assert_equal true, ingest.messages.empty?
    assert_nil ingest.stage
    # ingest.process!
    # assert_equal :started, ingest.state
    # ingest.log! :started, "working"
    ingest.update_attributes(stage: "copy_object")

    ingest.clear_terminate!
    assert_equal false, ingest.terminate?
    ingest.stop!
    assert_equal :stopping, ingest.state
    assert_equal true, ingest.terminate?
    ingest.process!
    assert_equal :stopped, ingest.state
    assert_not_nil ingest.stopped_at

    ingest.start!
    assert_equal :starting, ingest.state
    ingest.process!
    assert_equal :started, ingest.state
    assert_not_nil ingest.started_at

    ingest.stop!
    assert_equal :stopping, ingest.state
    ingest.process!
    assert_equal :stopped, ingest.state
    assert_not_nil ingest.stopped_at

    ingest.clear_terminate!
    assert_equal false, ingest.terminate?
    ingest.reset!
    assert_equal :resetting, ingest.state
    assert_equal true, ingest.terminate?
    ingest.process!
    assert_equal :reset, ingest.state
    assert_not_nil ingest.reset_at
    assert_equal 2, ingest.iteration

    ingest.start!
    assert_equal :starting, ingest.state
    ingest.process!
    assert_equal :started, ingest.state
    assert_not_nil ingest.started_at

    ingest.finish!
    assert_equal :finished, ingest.state
    assert_not_nil ingest.finished_at

    ingest.remove!
    assert_equal :removing, ingest.state
    ingest.process!
    assert_equal :removed, ingest.state
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
  
=begin
  should "delegate to @upload#s3_key" do
    ingest = FactoryGirl.create(:ingest_audio)
    assert_not_nil ingest.s3_key
  end

  should "utilize @ingest#s3_url or delegate to @upload#s3_url" do
    ingest = FactoryGirl.create(:ingest_audio)
    assert_not_nil ingest.s3_url
    assert_equal ingest.upload.s3_url, ingest.s3_url
    ingest.update_attribute(:s3_url, "http://s3.amazonaws.com/dropbox/changed.m4a")
    ingest = Ingest.find(ingest.id)
    assert_equal "http://s3.amazonaws.com/dropbox/changed.m4a", ingest.s3_url
    assert_not_equal ingest.upload.s3_url, ingest.s3_url
  end
=end
  
  should "set progress" do
    ingest = FactoryGirl.create(:ingest_audio)
    ingest.set_progress!(5) and ingest.reload
    assert_equal 5, ingest.progress
    ingest.set_progress!(75.5) and ingest.reload
    assert_equal 76, ingest.progress
    ingest.set_progress!(101) and ingest.reload
    assert_equal 100, ingest.progress
  end

  should "increment progress" do
    ingest = FactoryGirl.create(:ingest_audio)
    ingest.set_progress!(10) and ingest.reload
    assert_equal 10, ingest.progress
    175.times do |index|
      ingest.increment_progress! 1, 175, 0.8
    end
    assert_equal 90, ingest.progress
    ingest.increment_progress! 1, 175, 0.8
    assert_equal 90, ingest.progress
  end
end
