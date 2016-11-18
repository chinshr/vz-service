require 'test_helper'

class BarWorker < ApplicationWorker; end
module FooIngest; end
class FooIngest::BazWorker < ApplicationWorker; end

class ApplicationWorkerTest < ActiveSupport::TestCase
  context "class" do

    should "#queue_name" do
      assert_equal "BAR_TEST_QUEUE", BarWorker.queue_name
      assert_equal "FOO_INGEST_BAZ_TEST_QUEUE", FooIngest::BazWorker.queue_name
    end

    should "BarWorker queue" do
      assert_equal "empty", BarWorker.queue.name
    end

    context "Worker::Ingest::Base" do
      setup do
        @ingest = FactoryGirl.create(:media_ingest_as_audio)
        @queue = mock("AWS::SQS::QueueInstance")
        ApplicationWorker.expects(:queue).returns(@queue)
      end

      should "#perform_async" do
        assert_difference "Ingest::Worker.count" do
          @queue.expects(:send_message).with({ingest_id: @ingest.id, worker_id: Ingest::Worker.sort_order("created_at" => "asc").last.id + 1}.to_json)
          BarWorker.perform_async(ingest_id: @ingest.id)
        end
      end

      should "#perform_later" do
        assert_difference "Ingest::Worker.count" do
          @queue.expects(:send_message).with({ingest_id: @ingest.id, worker_id: Ingest::Worker.sort_order("id" => "asc").last.id + 1}.to_json)
          result = BarWorker.perform_later(ingest_id: @ingest.id)
        end
      end

      should "#perform_workflow" do
        @queue.expects(:send_message).with({ingest_id: 1, workflow: true}.to_json)
        FooIngest::BazWorker.perform_workflow(1)
      end
    end
  end
end
