require 'test_helper'

class Ingest::StartWorkerTest < ActiveSupport::TestCase
  context "class" do
    setup do
      Worker::Ingest::Base.queues = {}
    end

    should "#queue_name" do
      assert_equal "START_TEST_QUEUE", Ingest::StartWorker.queue_name
    end

    should "#stage_name" do
      assert_equal :start, Ingest::StartWorker.stage_name
    end

    should "#queues" do
      assert_equal({}, Ingest::StartWorker.queues)
    end

    should "have workflow_stage_id" do
      assert_equal 100, Ingest::StartWorker.workflow_stage_id
    end

    should "#perform_workflow" do
      result = Ingest::StartWorker.perform_workflow(1)
      assert_equal({ingest_id: 1, workflow: true}.to_json, result)
    end
  end
end