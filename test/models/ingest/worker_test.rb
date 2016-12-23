require 'test_helper'
require "#{Rails.root}/app/models/ingest/worker"

class Ingest::WorkerTest < ActiveSupport::TestCase
  context "units" do
    setup do
      ApplicationWorker.any_instance.stubs(:perform).returns({})
    end

    context "associations" do
      should belong_to :ingest
      should belong_to :server
    end

    context "validations" do
      should validate_presence_of :worker_name
      should validate_presence_of :ingest
    end

    should "have uid" do
      @worker = FactoryGirl.create(:ingest_worker)
      assert_not_nil @worker.uid
    end

    should "#create" do
      assert_difference "Ingest::Worker.count", 1 do
        assert_enqueued_with(job: Ingest::Server::RestartJob) do
          Ingest::Worker.create(worker_name: "ingest/media_ingest/harvest_worker",
            ingest: FactoryGirl.create(:media_ingest_as_audio), server: FactoryGirl.create(:cpw_ingest_server))
        end
      end
    end

    should "#worker_class" do
      worker = Ingest::Worker.new(worker_name: "ingest/media_ingest/harvest_worker")
      assert_equal Ingest::MediaIngest::HarvestWorker, worker.worker_class

      worker = Ingest::Worker.new(worker_name: nil)
      assert_equal nil, worker.worker_class

      worker = Ingest::Worker.new(worker_name: "")
      assert_equal nil, worker.worker_class

      worker = Ingest::Worker.new(worker_name: "Foobar")
      assert_equal nil, worker.worker_class
    end

    context "#related_ingest_stage" do
      should "not have without worker_name" do
        assert_nil Ingest::Worker.new(ingest: FactoryGirl.create(:media_ingest_as_audio)).related_ingest_stage
      end

      should "not have without ingest" do
        assert_nil Ingest::Worker.new(worker_name: "ingest/media_ingest/harvest_worker").related_ingest_stage
      end

      should "not have for ingest without stages" do
        assert_nil Ingest::Worker.new(ingest: Ingest.new).related_ingest_stage
      end

      should "not have with unstagable worker_name" do
        assert_nil Ingest::Worker.new(ingest: FactoryGirl.create(:media_ingest_as_audio),
          worker_name: "ingest/remove_worker").related_ingest_stage
      end

      should "return with stagable worker_name" do
        assert_equal :harvest_stage, Ingest::Worker.new(ingest: FactoryGirl.create(:media_ingest_as_audio),
          worker_name: "ingest/media_ingest/harvest_worker").related_ingest_stage
      end
    end

    context "#related_ingest_stage?" do
      should "be false without stages" do
        assert_equal false, Ingest::Worker.new.related_ingest_stage?
      end

      should "be true with stagable worker_name" do
        assert_equal true, Ingest::Worker.new(ingest: FactoryGirl.create(:media_ingest_as_audio),
          worker_name: "ingest/media_ingest/harvest_worker").related_ingest_stage?
      end
    end

    context "#could_forward_ingest_stage?" do

      should "be able to forward to next stage" do
        ingest = FactoryGirl.create(:media_ingest_as_audio)
        worker = FactoryGirl.create(:ingest_worker, :running, ingest: ingest,
          worker_name: "ingest/media_ingest/harvest_worker")
        assert_equal :harvest_stage, worker.related_ingest_stage
        assert_equal :begin_stage, ingest.stage
        assert_equal true, worker.could_forward_ingest_stage?
      end

      should "not be able to forward to next stage because it's not in consecutive order" do
        ingest = FactoryGirl.create(:media_ingest_as_audio)
        worker = FactoryGirl.create(:ingest_worker, :running, ingest: ingest,
          worker_name: "ingest/media_ingest/transcode_worker")
        assert_equal :transcode_stage, worker.related_ingest_stage
        assert_equal :begin_stage, ingest.stage
        assert_equal false, worker.could_forward_ingest_stage?
      end
    end

    context "scopes" do
      setup do
        @worker = FactoryGirl.create(:ingest_worker, :running)
      end

      should "have filtered scopes" do
        assert_equal [:any_of_status, :none_of_status, :sort_order, :reverse_sort,
          :any_of_state, :none_of_state, :offset, :limit, :ingest_id].to_set,
          Ingest::Worker.scopes.to_set
      end

      should "#any_of_status" do
        @worker.update_attribute(:aasm_state, "running")
        assert_equal [@worker], Ingest::Worker.any_of_status([Ingest::Worker::STATE_RUNNING])
      end

      should "#none_of_status" do
        @worker.update_attribute(:aasm_state, "running")
        assert_equal [@worker], Ingest::Worker.none_of_status([Ingest::Worker::STATE_CREATED, Ingest::Worker::STATE_STOPPED])
      end

      should "#any_of_state" do
        @worker.update_attribute(:aasm_state, "running")
        assert_equal [@worker], Ingest::Worker.any_of_state(["running"])
      end

      should "#none_of_state" do
        @worker.update_attribute(:aasm_state, "running")
        assert_equal [@worker], Ingest::Worker.none_of_state(["created", "stopped"])
      end

      should "#sort_order" do
        @worker.update_attribute(:aasm_state, "running")
        assert_equal [@worker], Ingest::Worker.sort_order("id" => "asc").reverse_sort("true").limit(1)
        assert_equal [@worker], Ingest::Worker.sort_order("created_at" => "asc").reverse_sort("true").limit(1)
        assert_equal [@worker], Ingest::Worker.sort_order("started_at" => "asc").reverse_sort("true").limit(1)
        assert_equal [@worker], Ingest::Worker.sort_order("stopped_at" => "asc").reverse_sort("true").limit(1)
      end

      should "#ingest_id" do
        assert_equal @worker, Ingest::Worker.ingest_id(@worker.ingest_id).last
      end

      should "#active" do
        ingest = FactoryGirl.create(:media_ingest_as_audio,
          aasm_state: "stopping", aasm_stage: "split_stage",
          busy: true, terminate: false)
        w1 = FactoryGirl.create(:ingest_worker, :finished, worker_name: "ingest/media_ingest/harvest_worker", ingest: ingest)
        w2 = FactoryGirl.create(:ingest_worker, :running, worker_name: "ingest/media_ingest/transcode_worker", ingest: ingest)
        w3 = FactoryGirl.create(:ingest_worker, :stopped, worker_name: "ingest/media_ingest/split_worker", ingest: ingest)
        w4 = FactoryGirl.create(:ingest_worker, :created, worker_name: "ingest/media_ingest/harvest_worker", ingest: ingest)
        assert_equal [w2, w4, @worker].to_set, Ingest::Worker.active.to_set
      end

    end # context "scopes"

    context "state machine" do
      should "be in initial state" do
        @worker = FactoryGirl.create(:ingest_worker)
        assert_equal :created, @worker.state
        assert_equal Ingest::Worker::STATE_CREATED, @worker.status
      end

      should "#start!" do
        @worker = FactoryGirl.create(:ingest_worker)
        @worker.expects(:after_commit_event_start).once
        @worker.expects(:after_enter_running).once
        assert_equal true, @worker.start!
        assert_equal :running, @worker.state
        assert_equal Ingest::Worker::STATE_RUNNING, @worker.status
        assert_not_nil @worker.started_at
      end

      should "#stop! when worker is 'running'" do
        @worker = FactoryGirl.create(:ingest_worker, :running)
        @worker.expects(:after_commit_event_stop).once
        @worker.expects(:after_enter_stopped).once
        assert_equal true, @worker.stop!
        assert_equal :stopped, @worker.state
        assert_equal Ingest::Worker::STATE_STOPPED, @worker.status
        assert_not_nil @worker.stopped_at
      end

      should "#stop! when worker is 'stopped'" do
        @worker = FactoryGirl.create(:ingest_worker, :stopped)
        @worker.expects(:after_commit_event_stop).once
        @worker.expects(:after_enter_stopped).once
        assert_equal true, @worker.stop!
        assert_equal :stopped, @worker.state
      end

      should "#stop! when ingest 'starting'" do
        @worker = FactoryGirl.create(:ingest_worker, :stopped, ingest_iteration: 1, worker_name: "ingest/media_ingest/harvest_worker",
          ingest: FactoryGirl.create(:media_ingest_as_video, iteration: 1, aasm_stage: "harvest_stage", aasm_state: "starting", busy: true, terminate: false))
        assert_equal true, @worker.stop!
        assert_equal :stopped, @worker.state
        assert_equal :stopping, @worker.ingest.state
        assert_equal false, @worker.ingest.busy?
        assert_equal true, @worker.ingest.terminate?
      end

      should "#stop! when created" do
        @worker = FactoryGirl.create(:ingest_worker)
        @worker.expects(:after_commit_event_stop).once
        @worker.expects(:after_enter_stopped).once
        assert_equal true, @worker.stop!
        assert_equal :stopped, @worker.state
      end

      should "#finish! to finished" do
        @worker = FactoryGirl.create(:ingest_worker, :running, ingest_iteration: 1,
          ingest: FactoryGirl.create(:media_ingest_as_audio, iteration: 1))
        @worker.expects(:after_commit_event_finish).once
        @worker.expects(:after_enter_finished).once
        assert_equal true, @worker.finish!
        assert_equal :finished, @worker.state
        assert_equal Ingest::Worker::STATE_FINISHED, @worker.status
        assert_not_nil @worker.finished_at
      end

      should "event=finish when stopped" do
        @worker = FactoryGirl.create(:ingest_worker, :stopped)
        @worker.expects(:after_enter_finished).never
        assert_equal false, @worker.update_attributes(event: 'finish')
        assert_equal :stopped, @worker.state
      end

      should "#status" do
        @worker = FactoryGirl.create(:ingest_worker, :running)
        assert_equal Ingest::Worker::STATE_RUNNING, @worker.status
      end

      context "#after_enter_running" do
        should "start ingest and forward stage" do
          ingest = FactoryGirl.create(:media_ingest_as_audio)
          assert_equal :starting, ingest.state
          assert_equal :begin_stage, ingest.stage
          assert_equal false, ingest.busy?
          assert_difference "Ingest::Worker.count", 1 do
            worker = Ingest::Worker.create(worker_name: "ingest/media_ingest/harvest_worker",
              ingest: ingest)
            assert_equal :created, worker.state
            assert_equal true, worker.start!
            assert_equal :running, worker.state
            assert_equal :started, ingest.state
            assert_equal :harvest_stage, ingest.stage
            assert_equal true, ingest.busy?
          end
        end

        should "forward stage" do
          ingest = FactoryGirl.create(:media_ingest_as_audio, aasm_state: "started", aasm_stage: "harvest_stage")
          assert_equal :started, ingest.state
          assert_equal :harvest_stage, ingest.stage
          assert_equal false, ingest.busy?
          assert_difference "Ingest::Worker.count", 1 do
            worker = Ingest::Worker.create(worker_name: "ingest/media_ingest/transcode_worker",
              ingest: ingest)
            assert_equal :created, worker.state
            assert_equal true, worker.start!
            assert_equal :running, worker.state
            assert_equal :started, ingest.state
            assert_equal :transcode_stage, ingest.stage
            assert_equal true, ingest.busy?
          end
        end
      end

      context "#after_enter_finished" do
        should "trigger next stage when workflow is not terminated" do
          ingest = FactoryGirl.create(:media_ingest_as_audio, aasm_state: "started", aasm_stage: "harvest_stage",
            busy: true)
          assert_equal :started, ingest.state
          assert_equal :harvest_stage, ingest.stage
          assert_equal true, ingest.busy?
          assert_equal false, ingest.terminate?
          assert_difference "Ingest::Worker.count", 1 do
            Ingest::MediaIngest::TranscodeWorker.expects(:perform_workflow).with(ingest.id).once
            worker = Ingest::Worker.create(worker_name: "ingest/media_ingest/harvest_worker",
              ingest: ingest, aasm_state: "running")
            assert_equal :running, worker.state
            assert_equal true, worker.finish!
            assert_equal :finished, worker.state
            assert_equal :started, ingest.state
            assert_equal false, ingest.busy?
          end
        end

        should "not trigger next stage when workflow is terminated" do
          ingest = FactoryGirl.create(:media_ingest_as_audio, aasm_state: "started", aasm_stage: "harvest_stage",
            busy: true, terminate: true)
          assert_equal :started, ingest.state
          assert_equal :harvest_stage, ingest.stage
          assert_equal true, ingest.busy?
          assert_equal true, ingest.terminate?
          assert_difference "Ingest::Worker.count", 1 do
            Ingest::MediaIngest::TranscodeWorker.expects(:perform_workflow).with(ingest.id).never
            worker = Ingest::Worker.create(worker_name: "ingest/media_ingest/harvest_worker",
              ingest: ingest, aasm_state: "running")
            assert_equal true, worker.ingest.stop!
            assert_equal :stopping, worker.ingest.state
            assert_equal true, worker.ingest.terminate
            assert_equal :running, worker.state
            assert_equal true, worker.finish!
            assert_equal :stopped, worker.state
            assert_equal false, ingest.busy?
            assert_equal true, ingest.terminate?
          end
        end

        should "finish ingest" do
          ingest = FactoryGirl.create(:media_ingest_as_audio, aasm_state: "started", aasm_stage: "archive_stage",
            busy: true)
          assert_equal :started, ingest.state
          assert_equal :archive_stage, ingest.stage
          assert_equal true, ingest.busy?
          assert_difference "Ingest::Worker.count", 1 do
            worker = Ingest::Worker.create(worker_name: "ingest/media_ingest/archive_worker",
              ingest: ingest, aasm_state: "running")
            assert_equal :running, worker.state
            assert_equal true, worker.finish!
            assert_equal :finished, worker.state
            assert_equal :finished, ingest.state
            assert_equal false, ingest.busy?
          end
        end
      end

      context "#after_enter_stopped" do
        should "stop ingest" do
          ingest = FactoryGirl.create(:media_ingest_as_audio, aasm_state: "started", aasm_stage: "harvest_stage",
            busy: true)
          assert_equal :started, ingest.state
          assert_equal :harvest_stage, ingest.stage
          assert_equal true, ingest.busy?
          assert_difference "Ingest::Worker.count", 1 do
            worker = Ingest::Worker.create(worker_name: "ingest/media_ingest/harvest_worker",
              ingest: ingest, aasm_state: "running")
            assert_equal :running, worker.state
            assert_equal true, worker.stop!
            assert_equal :stopped, worker.state
            assert_equal :stopping, ingest.state
            assert_equal true, ingest.terminate?
            assert_equal false, ingest.busy?
          end
        end
      end

    end # context state machine

    context "instance_id" do
      setup do
        @server = FactoryGirl.create(:cpw_ingest_server)
      end

      should "set server from instance id on create" do
        @worker = FactoryGirl.create(:ingest_worker, instance_id: @server.instance_id)
        assert_equal @server, @worker.server
        assert_equal @server.instance_id, @worker.instance_id
      end

      should "not get instance_id without server on create" do
        @worker = FactoryGirl.create(:ingest_worker)
        assert_nil @worker.instance_id
      end

      should "get instance_id from server instance on create" do
        @worker = FactoryGirl.create(:ingest_worker, server: @server)
        assert_equal @server.instance_id, @worker.instance_id
      end

      should "set server from instance id on update" do
        @worker = FactoryGirl.create(:ingest_worker)
        @worker.update_attributes(instance_id: @server.instance_id)
        assert_equal @server, @worker.server
        assert_equal @server.instance_id, @worker.instance_id
      end

    end

    should "set ingest iteration from ingest" do
      ingest = FactoryGirl.create(:media_ingest_as_audio, iteration: 12)
      worker = Ingest::Worker.create(ingest: ingest, worker_name: "ingest/media_ingest/harvest_worker")
      assert_equal ingest.iteration, worker.ingest_iteration
    end

    context "#can_start?" do
      should "be true when ingest starting and not terminated" do
        worker = FactoryGirl.create(:ingest_worker)
        assert_equal true, worker.ingest.starting?
        assert_equal true, worker.ingest.not_terminate?
        assert_equal true, worker.send(:can_start?)
      end

      should "be true when ingest started and not terminated" do
        worker = FactoryGirl.create(:ingest_worker)
        assert_equal true, worker.ingest.process!
        assert_equal true, worker.ingest.started?
        assert_equal true, worker.ingest.not_terminate?
        assert_equal true, worker.send(:can_start?)
      end

      should "be false when ingest starting and terminated" do
        worker = FactoryGirl.create(:ingest_worker)
        worker.ingest.update_attribute(:terminate, true)
        assert_equal true, worker.ingest.starting?
        assert_equal true, worker.ingest.terminate?
        assert_equal false, worker.send(:can_start?)
      end

      should "be false when ingest started and terminated" do
        worker = FactoryGirl.create(:ingest_worker)
        worker.ingest.update_attributes({aasm_state: "started", terminate: true})
        assert_equal true, worker.ingest.started?
        assert_equal true, worker.ingest.terminate?
        assert_equal false, worker.send(:can_start?)
      end

      should "be false when ingest in other states but not terminated" do
        worker = FactoryGirl.create(:ingest_worker)
        worker.ingest.update_attributes({aasm_state: "stopping"})
        assert_equal true, worker.ingest.stopping?
        assert_equal false, worker.ingest.terminate?
        assert_equal false, worker.send(:can_start?)
      end
    end

    context "delegate" do
      setup do
        @worker = FactoryGirl.create(:ingest_worker, progress: 21, messages: {"test" => "foo"})
      end

      should delegate :progress, to: :ingest
      should "delegate :progress, to: :ingest" do
        assert_equal @worker.ingest.progress, @worker.progress
      end

      should delegate :progress=, to: :ingest
      should "delegate :progress=, to: :ingest" do
        value = 89
        @worker.progress = value
        assert_equal value, @worker.progress
        assert_equal true, @worker.save
        @worker = Ingest::Worker.find(@worker.id)
        assert_equal value, @worker.progress
      end
    end

    should "log messages" do
      messages = {"foo" => [{"bar" => 1}]}
      worker = FactoryGirl.create(:ingest_worker)
      worker.update_attribute(:messages, messages)
      assert_equal messages, worker.reload.messages
    end

    should "have `lock_count` column" do
      worker = FactoryGirl.create(:ingest_worker)
      assert_equal 0, worker.lock_count
    end
  end

  context "integration" do
    setup do
      AWS::SQS::Queue.any_instance.stubs(:send_message).returns({})
    end

    context "start / stop" do
      setup do
        @ingest = FactoryGirl.create(:media_ingest_as_audio, aasm_state: "started", aasm_stage: "transcode_stage",
          busy: true, terminate: false, iteration: 0)
        @harvest_worker = FactoryGirl.create(:ingest_worker, :finished, ingest: @ingest,
          worker_name: "ingest/media_ingest/harvest_worker", ingest_iteration: 0)
        @transcode_worker = FactoryGirl.create(:ingest_worker, :running, ingest: @ingest,
          worker_name: "ingest/media_ingest/transcode_worker", ingest_iteration: 0)
      end

      should "check setup" do
        assert_equal :started, @ingest.state
        assert_equal :transcode_stage, @ingest.stage
        assert_equal true, @ingest.busy?
        assert_equal false, @ingest.terminate?
        assert_equal 2, @ingest.workers.count
        assert_equal @ingest.iteration, @harvest_worker.ingest_iteration
        assert_equal @ingest.iteration, @transcode_worker.ingest_iteration
      end

      should "`finish` transcode worker" do
        @transcode_worker.update_attributes({event: "finish"})
        assert_equal true, @transcode_worker.finished?
        assert_equal false, @ingest.busy?
        assert_equal false, @ingest.terminate?
        assert_equal 3, @ingest.workers.count
        assert_equal 1, @ingest.workers.where(worker_name: "ingest/media_ingest/split_worker").count
      end

      should "`start` split worker" do
        @transcode_worker.update_attributes({event: "finish"})
        assert_equal true, @transcode_worker.finished?
        split_worker = @ingest.workers.where(worker_name: "ingest/media_ingest/split_worker").first
        assert_not_nil split_worker
        assert_equal true, split_worker.created?
        assert_equal false, @ingest.busy?
        assert_equal false, @ingest.terminate?
        split_worker.update_attributes({event: "start", instance_id: "i-0f6eea52db2f0c4ff"})
        assert_equal true, split_worker.errors.empty?
        assert_equal true, split_worker.running?
        assert_equal true, @ingest.busy?
        # try to start again, but already running
        split_worker.update_attributes({event: "start", instance_id: "i-0f6eea52db2f0c4ff"})
        assert_equal false, split_worker.errors.empty?
        assert_equal true, split_worker.running?
      end
    end

    context "archive to end stage" do
      setup do
        @ingest = FactoryGirl.create(:media_ingest_as_audio, aasm_state: "started", aasm_stage: "split_stage",
          busy: true, terminate: false, iteration: 0, progress: 80)
        @split_worker = FactoryGirl.create(:ingest_worker, :running, ingest: @ingest,
          worker_name: "ingest/media_ingest/split_worker", ingest_iteration: 0)
      end

      should "no duplicate archive worker" do
        assert_equal :started, @ingest.state
        assert_equal :split_stage, @ingest.stage
        assert_equal true, @ingest.busy?
        assert_equal false, @ingest.terminate?
        assert_equal 1, @ingest.workers.count
        @split_worker.update_attributes({event: "finish"})
        assert_equal false, @ingest.busy?
        assert_equal 2, @ingest.workers.count
        archive_worker = @ingest.workers.where(worker_name: "ingest/media_ingest/archive_worker").first
        assert_not_nil archive_worker
        assert_equal :created, archive_worker.state
        ingest_id, archive_worker_id = @ingest.id, archive_worker.id
        assert_equal :split_stage, @ingest.stage
        # shoryuken 1st archive worker trying to lock
        archive_worker1 = Ingest::Worker.filter({ingest_id: ingest_id}).find(archive_worker_id)
        assert_equal :created, archive_worker1.state
        archive_worker1.update_attributes({event: "start", instance_id: "xyz"})
        assert_equal :running, archive_worker1.state
        assert_equal 1, archive_worker1.lock_count
        assert_equal :archive_stage, @ingest.reload.stage
        # rogue 2nd archive worker also trying to lock
        archive_worker2 = Ingest::Worker.filter({ingest_id: ingest_id}).find(archive_worker_id)
        assert_equal :running, archive_worker2.state
        archive_worker2.update_attributes({event: "start", instance_id: "xyz"})
        assert_equal false, archive_worker2.errors.blank?
        assert_equal 1, archive_worker2.lock_count
        # 1st worker finishes
        archive_worker1.update_attributes({event: "finish"})
        assert_equal :finished, archive_worker1.state
        # were are done, right?
        assert_equal :finished, @ingest.reload.state
        assert_equal :end_stage, @ingest.stage
        assert_equal 100.0, @ingest.progress
      end
    end
  end
end
