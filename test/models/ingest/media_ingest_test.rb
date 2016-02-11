require 'test_helper'

class Ingest::MediaIngestTest < ActiveSupport::TestCase
  setup do
    ActionMailer::Base.deliveries.clear
  end

  context "validations" do
    should validate_presence_of :document
    should validate_presence_of(:upload).on(:create)
  end

  context "delegates" do
    should "delegate to document getters" do
      document = FactoryGirl.create(:document)
      ingest = FactoryGirl.create(:media_ingest_as_audio, :document => document)
      assert_equal document.title, ingest.title
      assert_equal document.description, ingest.description
      assert_equal document.tag_list, ingest.tag_list
      assert_equal document.slug, ingest.slug
      assert_equal document.slug_id, ingest.slug_id
    end

    should "delegate to document setters" do
      document = FactoryGirl.create(:document)
      ingest = FactoryGirl.create(:media_ingest_as_audio, :document => document)
      ingest.title       = "Wizard of Oz!"
      ingest.description = "The wonderful Wizard of Oz!"
      ingest.tag_list    = ["wizard", "oz"]
      assert_equal document.title, ingest.title
      assert_equal document.description, ingest.description
      assert_equal document.tag_list, ingest.tag_list
    end
  end

  should "have segments and remove messages when reset" do
    document = FactoryGirl.create(:document)
    ingest   = FactoryGirl.create(:media_ingest_as_audio, :document => document)
    ingest.log! :error, "error message"
    assert_equal %({"error"=>["error message"]}), ingest.messages.to_s
    #ingest.start!
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
      ingest = FactoryGirl.create(:media_ingest_as_audio)
      ingest.update_attributes(aasm_state: "created")
      assert_equal :created, ingest.state

      Ingest::MediaIngest::HarvestWorker.expects(:perform_workflow).with(ingest.id).once

      ingest.start!  # inside model!
      assert_equal :starting, ingest.state
    end

    should "process (from starting)" do
      ingest = FactoryGirl.create(:media_ingest_as_audio, aasm_state: "starting")
      assert_equal :starting, ingest.state

      Ingest::MediaIngest::HarvestWorker.expects(:perform_workflow).with(ingest.id).never

      ingest.process!  # inside worker!
      assert_equal :started, ingest.state
    end

    should "stop (from started)" do
      ingest = FactoryGirl.create(:media_ingest_as_audio, aasm_state: "started")
      assert_equal :started, ingest.state

      Ingest::MediaIngest::HarvestWorker.expects(:perform_workflow).with(ingest.id).never

      ingest.stop!  # inside model!
      assert_equal :stopping, ingest.state
    end

    should "process (from stopping)" do
      ingest = FactoryGirl.create(:media_ingest_as_audio, aasm_state: "stopping")
      assert_equal :stopping, ingest.state

      Ingest::MediaIngest::HarvestWorker.expects(:perform_workflow).with(ingest.id).never

      ingest.process!  # inside worker!
      assert_equal :stopped, ingest.state
    end

    should "reset (from stopped)" do
      ingest = FactoryGirl.create(:media_ingest_as_audio, aasm_state: "stopped")
      ingest.update_attributes(aasm_state: "stopped")
      assert_equal :stopped, ingest.state

      Ingest::MediaIngest::HarvestWorker.expects(:perform_workflow).with(ingest.id).never

      ingest.reset!  # inside model!
      assert_equal :resetting, ingest.state
      assert_equal 0, ingest.iteration
    end

    should "process (from resetting)" do
      ingest = FactoryGirl.create(:media_ingest_as_audio)
      ingest.update_attributes(aasm_state: "resetting")
      assert_equal :resetting, ingest.state

      Ingest::MediaIngest::HarvestWorker.expects(:perform_workflow).with(ingest.id).never

      ingest.process!  # inside worker!
      assert_equal :reset, ingest.state
      assert_equal 1, ingest.iteration
    end

    should "remove (from stopped)" do
      ingest = FactoryGirl.create(:media_ingest_as_audio)
      ingest.update_attributes(aasm_state: "stopped")

      assert_equal :stopped, ingest.state

      Ingest::MediaIngest::HarvestWorker.expects(:perform_workflow).with(ingest.id).never

      ingest.remove!  # inside model!
      assert_equal :removing, ingest.state
    end

    should "process (from removing)" do
      ingest = FactoryGirl.create(:media_ingest_as_audio, aasm_state: "removing")
      assert_equal :removing, ingest.state

      Ingest::MediaIngest::HarvestWorker.expects(:perform_workflow).with(ingest.id).never

      ingest.process!  # inside worker!
      assert_equal :removed, ingest.state
    end
  end

  should "finish process with user and email" do
    ingest = FactoryGirl.create(:media_ingest_as_audio,
      aasm_state: "created", :user => FactoryGirl.create(:user))

    assert_equal :starting, ingest.state
    #ingest.start!  # inside model!
    assert_equal :starting, ingest.state

    ingest.process!  # inside worker!
    assert_equal :started, ingest.state

    ingest.finish!  # inside worker!
    assert_equal :finished, ingest.state

    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_equal "Finished, '#{ingest.upload.file_name}' has been transcribed.", ActionMailer::Base.deliveries[0].subject
  end

  context "stage related" do
    should "have stages" do
      stages = [:begin_stage, :harvest_stage, :transcode_stage, :split_stage, :archive_stage, :end_stage]
      assert_equal stages, Ingest::MediaIngest.stages
      assert_equal stages, Ingest::MediaIngest.new.stages
    end

    context "class" do

      should "have stage_names" do
        assert_equal ["begin", "harvest", "transcode", "split", "archive", "end"],
          Ingest::MediaIngest.stage_names
      end

      should "class name from stage" do
        assert_equal Ingest::MediaIngest::ArchiveWorker, Ingest::MediaIngest.worker_class_from_stage("archive_stage")
        assert_equal Ingest::MediaIngest::ArchiveWorker, Ingest::MediaIngest.worker_class_from_stage(:archive_stage)
        assert_equal Ingest::MediaIngest::ArchiveWorker, Ingest::MediaIngest.worker_class_from_stage("archive")
      end
    end

    should "have stage" do
      ingest = FactoryGirl.create(:media_ingest_as_audio)
      assert_equal :begin_stage, ingest.stage
    end

    should "normalize with #source_stage" do
      ingest = Ingest::MediaIngest.new
      assert_equal :archive_stage, ingest.send(:source_stage, "archive_stage")
      assert_equal :archive_stage, ingest.send(:source_stage, "archive")
    end

    should "return #stage_after" do
      ingest = Ingest::MediaIngest.new
      assert_equal :harvest_stage, ingest.send(:stage_after, :"begin_stage")
      assert_equal :archive_stage, ingest.send(:stage_after, "split")
      assert_equal :archive_stage, ingest.send(:stage_after, "split_stage")
      assert_equal nil, ingest.send(:stage_after, "end_stage")
      assert_equal nil, ingest.send(:stage_after, nil)
    end

    should "return #stage_before" do
      ingest = Ingest::MediaIngest.new
      assert_equal nil, ingest.send(:stage_before, :"begin_stage")
      assert_equal :transcode_stage, ingest.send(:stage_before, "split")
      assert_equal :transcode_stage, ingest.send(:stage_before, "split_stage")
      assert_equal :archive_stage, ingest.send(:stage_before, :"end_stage")
      assert_equal nil, ingest.send(:stage_before, nil)
    end

    should "include stage machine events" do
      ingest = Ingest::MediaIngest.new
      assert_equal true, ingest.events.include?(:forward_to_harvest_stage)
      assert_equal true, ingest.events.include?(:reset_stage)
      assert_equal true, ingest.events.include?(:fast_forward_stage)
    end

    context "traverse stages" do
      context "forward from 'begin' stage" do
        should "forward 'begin' to 'harvest' stage when state 'starting'" do
          @ingest = FactoryGirl.create(:media_ingest_as_audio, aasm_state: "starting")
          assert_equal :begin_stage, @ingest.stage
          assert_equal 0, @ingest.progress
          assert_equal true, @ingest.update_attributes(event: "forward_to_harvest_stage")
          assert_equal :harvest_stage, @ingest.stage
          assert_equal 10, @ingest.progress
        end

        should "forward 'begin' to 'harvest' stage, #start!, set busy when state 'starting'" do
          @ingest = FactoryGirl.create(:media_ingest_as_audio, aasm_state: "starting")
          assert_equal :starting, @ingest.state
          assert_equal :begin_stage, @ingest.stage
          assert_equal false, @ingest.busy?
          assert_equal true, @ingest.update_attributes(busy: true,
            event: :forward_to_harvest_stage,
            status: Ingest::STATE_STARTED)
          assert_equal :harvest_stage, @ingest.stage
          assert_equal :started, @ingest.state
          assert_equal true, @ingest.busy?
          assert_equal 10, @ingest.progress
        end

        should "not 'forward_stage' using event when state 'stopped'" do
          @ingest = FactoryGirl.create(:media_ingest_as_audio, aasm_state: "stopped")
          @ingest.fail!  # force to stopped!
          assert_equal :stopped, @ingest.state
          @ingest.event = "forward_to_harvest_stage"
          assert_equal false, @ingest.save
          assert_equal true, !!@ingest.errors[:status]
          assert_equal :begin_stage, @ingest.reload.stage
        end

        should "'forward_stage' using event when state 'starting'" do
          @ingest = FactoryGirl.create(:media_ingest_as_audio, aasm_state: "starting")
          @ingest.event = "forward_to_harvest_stage"
          assert_equal true, @ingest.save
          assert_equal :harvest_stage, @ingest.stage
        end
      end

      should "forward 'harvest' to 'transcode' stage" do
        @ingest = FactoryGirl.create(:media_ingest_as_audio, aasm_state: "started", aasm_stage: "harvest_stage")
        assert_equal :harvest_stage, @ingest.stage
        assert_equal true, @ingest.forward_to_transcode_stage!
        assert_equal :transcode_stage, @ingest.stage
        assert_equal 20, @ingest.progress
      end

      should "forward 'transcode' to 'split' stage" do
        @ingest = FactoryGirl.create(:media_ingest_as_audio, aasm_state: "started", aasm_stage: "transcode_stage")
        assert_equal :transcode_stage, @ingest.stage
        assert_equal true, @ingest.forward_to_split_stage!
        assert_equal :split_stage, @ingest.stage
        assert_equal 30, @ingest.progress
      end

      should "forward 'split' to 'archive' stage" do
        @ingest = FactoryGirl.create(:media_ingest_as_audio, aasm_state: "started", aasm_stage: "split_stage")
        assert_equal :split_stage, @ingest.stage
        assert_equal true, @ingest.forward_to_archive_stage!
        assert_equal :archive_stage, @ingest.stage
        assert_equal 90, @ingest.progress
      end

      should "not forward to 'archive' from 'archive'" do
        @ingest = FactoryGirl.create(:media_ingest_as_audio, aasm_state: "started", aasm_stage: "archive_stage")
        assert_equal :archive_stage, @ingest.stage
        assert_raise AASM::InvalidTransition do
          assert_equal false, @ingest.forward_to_archive_stage!
        end
      end

      should "not forward when terminated" do
        @ingest = FactoryGirl.create(:media_ingest_as_audio, aasm_state: "started", aasm_stage: "harvest_stage", terminate: true)
        assert_equal :harvest_stage, @ingest.stage
        assert_equal true, @ingest.terminate?
        assert_raise AASM::InvalidTransition do
          assert_equal false, @ingest.forward_to_transcode_stage!
        end
      end

      should "not forward with #event= when terminated" do
        @ingest = FactoryGirl.create(:media_ingest_as_audio, aasm_state: "started", aasm_stage: "harvest_stage", terminate: true)
        assert_equal :harvest_stage, @ingest.stage
        assert_equal true, @ingest.terminate?
        @ingest.event = :forward_to_transcode_stage
        assert_equal false, @ingest.save
      end

      should "not forward when busy" do
        @ingest = FactoryGirl.create(:media_ingest_as_audio, aasm_state: "started", aasm_stage: "harvest_stage", busy: true)
        assert_equal :harvest_stage, @ingest.stage
        assert_equal true, @ingest.busy?
        assert_raise AASM::InvalidTransition do
          assert_equal false, @ingest.forward_to_transcode_stage!
        end
      end

      should "not forward with #event= when busy" do
        @ingest = FactoryGirl.create(:media_ingest_as_audio, aasm_state: "started", aasm_stage: "harvest_stage", busy: true)
        assert_equal :harvest_stage, @ingest.stage
        assert_equal true, @ingest.busy?
        @ingest.event = :forward_to_transcode_stage
        assert_equal false, @ingest.save
      end

      should "reset stage" do
        @ingest = FactoryGirl.create(:media_ingest_as_audio, aasm_state: "finished", aasm_stage: "end_stage")
        assert_equal :end_stage, @ingest.stage
        assert_equal true, @ingest.reset_stage!
        assert_equal :begin_stage, @ingest.stage
      end
    end

    context "event start ingest" do

      should "start and trigger 'harvest' stage when created" do
        @ingest = FactoryGirl.create(:media_ingest_as_audio, aasm_state: "created")
        @ingest.update_attributes(aasm_state: "created", aasm_stage: "begin_stage")
        assert_equal :created, @ingest.state
        assert_equal :begin_stage, @ingest.stage
        Ingest::MediaIngest::HarvestWorker.expects(:perform_workflow).with(@ingest.id).once
        @ingest.start!
        assert_equal :begin_stage, @ingest.stage
      end

      should "rewind and trigger 'harvest' stage when start after stopped at 'harvest' stage" do
        @ingest = FactoryGirl.create(:media_ingest_as_audio, aasm_state: "stopped", aasm_stage: "harvest_stage")
        @ingest.update_attributes(aasm_state: "stopped", aasm_stage: "harvest_stage")
        assert_equal :stopped, @ingest.state
        assert_equal :harvest_stage, @ingest.stage
        Ingest::MediaIngest::HarvestWorker.expects(:perform_workflow).with(@ingest.id).once
        @ingest.start!
        assert_equal :begin_stage, @ingest.stage
      end

    end

    context "trigger stages" do

      should "trigger 'harvest' from 'begin' stage" do
        @ingest = FactoryGirl.create(:media_ingest_as_audio, aasm_state: "started")
        assert_equal :begin_stage, @ingest.stage
        Ingest::MediaIngest::HarvestWorker.expects(:perform_workflow).with(@ingest.id).once
        @ingest.update_attributes(trigger: @ingest.stage)
      end

      should "trigger 'transcode' from 'harvest' stage" do
        @ingest = FactoryGirl.create(:media_ingest_as_audio, aasm_state: "started", aasm_stage: "harvest_stage")
        assert_equal :harvest_stage, @ingest.stage
        Ingest::MediaIngest::TranscodeWorker.expects(:perform_workflow).with(@ingest.id).once
        @ingest.update_attributes(trigger: @ingest.stage)
      end

      should "trigger 'split' from 'transcode' stage" do
        @ingest = FactoryGirl.create(:media_ingest_as_audio, aasm_state: "started", aasm_stage: "transcode_stage")
        assert_equal :transcode_stage, @ingest.stage
        Ingest::MediaIngest::SplitWorker.expects(:perform_workflow).with(@ingest.id).once
        @ingest.update_attributes(trigger: @ingest.stage)
      end

      should "trigger 'archive' from 'split' stage" do
        @ingest = FactoryGirl.create(:media_ingest_as_audio, aasm_state: "started", aasm_stage: "split_stage")
        assert_equal :split_stage, @ingest.stage
        Ingest::MediaIngest::ArchiveWorker.expects(:perform_workflow).with(@ingest.id).once
        @ingest.update_attributes(trigger: @ingest.stage)
      end

      should "trigger 'end' from 'archive' stage" do
        @ingest = FactoryGirl.create(:media_ingest_as_audio, aasm_state: "started", aasm_stage: "archive_stage")
        assert_equal :archive_stage, @ingest.stage
        Ingest::MediaIngest::EndJob.expects(:perform_later).with(@ingest.id).once
        @ingest.update_attributes(trigger: @ingest.stage)
      end
    end
  end
end
