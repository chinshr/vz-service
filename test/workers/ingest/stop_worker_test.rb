require 'test_helper'

class Ingest::StopWorkerTest < ActiveSupport::TestCase
  context "class" do
    should "#queue_name" do
      assert_equal "STOP_TEST_QUEUE", Ingest::StopWorker.queue_name
    end

    should "#stage_name" do
      assert_equal :stop, Ingest::StopWorker.stage_name
    end

    should "have workflow_stage_id" do
      assert_equal nil, Ingest::StopWorker.workflow_stage_id
    end

    should "#perform_async" do
      result = Ingest::StopWorker.perform_async(1, {force: true})
      assert_equal({force: true, ingest_id: 1}.to_json, result)
    end
  end
end