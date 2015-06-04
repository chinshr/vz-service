require 'test_helper'

class Ingest::AudioIngestTest < ActiveSupport::TestCase
  setup do
    ActionMailer::Base.deliveries.clear
  end

  should "delegate to document getters" do
    document = FactoryGirl.create(:document)
    ingest = FactoryGirl.create(:ingest_audio, :document => document)
    assert_equal document.title, ingest.title
    assert_equal document.description, ingest.description
    assert_equal document.tag_list, ingest.tag_list
  end

  should "delegate to document setters" do
    document = FactoryGirl.create(:document)
    ingest = FactoryGirl.create(:ingest_audio, :document => document)
    ingest.title       = "Wizard of Oz!"
    ingest.description = "The wonderful Wizard of Oz!"
    ingest.tag_list    = ["wizard", "oz"]
    assert_equal document.title, ingest.title
    assert_equal document.description, ingest.description
    assert_equal document.tag_list, ingest.tag_list
  end

  should "have segments and remove messages when reset" do
    document = FactoryGirl.create(:document)
    ingest   = FactoryGirl.create(:ingest_audio, :document => document)
    ingest.log! :error, "error message"
    assert_equal %({"error"=>["error message"]}), ingest.messages.to_s
    ingest.start!
    assert_equal :starting, ingest.state
    ingest.process!
    assert_equal :started, ingest.state
    ingest.stop!
    assert_equal :stopping, ingest.state
    ingest.process!
    assert_equal :stopped, ingest.state
    ingest.reset!
    assert_equal :resetting, ingest.state
    assert_equal false, ingest.messages.empty?
    ingest.process!
    assert_equal :reset, ingest.state
    assert_equal true, ingest.messages.empty?
  end

  context "worker state machine process" do
    should "start" do
      ingest = FactoryGirl.create(:ingest_audio)
      assert_equal :created, ingest.state

      Ingest::StartWorker.expects(:perform_workflow).with(ingest.id).once
      Ingest::StopWorker.expects(:perform_workflow).with(ingest.id).never
      Ingest::ResetWorker.expects(:perform_workflow).with(ingest.id).never

      ingest.start!  # inside model!
      assert_equal :starting, ingest.state
    end

    should "process (from starting)" do
      ingest = FactoryGirl.create(:ingest_audio, aasm_state: "starting")
      assert_equal :starting, ingest.state

      Ingest::StartWorker.expects(:perform_workflow).with(ingest.id).never
      Ingest::StopWorker.expects(:perform_workflow).with(ingest.id).never
      Ingest::ResetWorker.expects(:perform_workflow).with(ingest.id).never

      ingest.process!  # inside worker!
      assert_equal :started, ingest.state
    end

    should "stop (from started)" do
      ingest = FactoryGirl.create(:ingest_audio, aasm_state: "started")
      assert_equal :started, ingest.state

      Ingest::StartWorker.expects(:perform_workflow).with(ingest.id).never
      Ingest::StopWorker.expects(:perform_workflow).with(ingest.id).once
      Ingest::ResetWorker.expects(:perform_workflow).with(ingest.id).never

      ingest.stop!  # inside model!
      assert_equal :stopping, ingest.state
    end

    should "process (from stopping)" do
      ingest = FactoryGirl.create(:ingest_audio, aasm_state: "stopping")
      assert_equal :stopping, ingest.state

      Ingest::StartWorker.expects(:perform_workflow).with(ingest.id).never
      Ingest::StopWorker.expects(:perform_workflow).with(ingest.id).never
      Ingest::ResetWorker.expects(:perform_workflow).with(ingest.id).never

      ingest.process!  # inside worker!
      assert_equal :stopped, ingest.state
    end

    should "reset (from stopped)" do
      ingest = FactoryGirl.create(:ingest_audio, aasm_state: "stopped")
      assert_equal :stopped, ingest.state

      Ingest::StartWorker.expects(:perform_workflow).with(ingest.id).never
      Ingest::StopWorker.expects(:perform_workflow).with(ingest.id).never
      Ingest::ResetWorker.expects(:perform_workflow).with(ingest.id).once

      ingest.reset!  # inside model!
      assert_equal :resetting, ingest.state
      assert_equal 0, ingest.iteration
    end

    should "process (from resetting)" do
      ingest = FactoryGirl.create(:ingest_audio, aasm_state: "resetting")
      assert_equal :resetting, ingest.state

      Ingest::StartWorker.expects(:perform_workflow).with(ingest.id).never
      Ingest::StopWorker.expects(:perform_workflow).with(ingest.id).never
      Ingest::ResetWorker.expects(:perform_workflow).with(ingest.id).never

      ingest.process!  # inside worker!
      assert_equal :reset, ingest.state
      assert_equal 1, ingest.iteration
    end
  end

  should "finish process with user and email" do
    ingest = FactoryGirl.create(:ingest_audio, :user => FactoryGirl.create(:user))

    ingest.start!  # inside model!
    assert_equal :starting, ingest.state

    ingest.process!  # inside worker!
    assert_equal :started, ingest.state

    ingest.finish!  # inside worker!
    assert_equal :finished, ingest.state

    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_equal "Finished, '#{ingest.upload.file_name}' has been transcribed.", ActionMailer::Base.deliveries[0].subject
  end
end
