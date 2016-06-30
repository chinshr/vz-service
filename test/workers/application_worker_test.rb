require 'test_helper'

class ::Ingest::BarWorker < ApplicationWorker; end
module ::Ingest::FooIngest; end
class ::Ingest::FooIngest::BazWorker < ApplicationWorker; end

class ApplicationWorkerTest < ActiveSupport::TestCase

  context "class" do
    setup do
      ApplicationWorker.queues = {}
    end

    should "#queue_name" do
      assert_equal "INGEST_BAR_TEST_QUEUE", Ingest::BarWorker.queue_name
      assert_equal "INGEST_FOO_INGEST_BAZ_TEST_QUEUE", Ingest::FooIngest::BazWorker.queue_name
    end

    should "provide queue" do
      assert_equal "SQSTestQueue", Ingest::BarWorker.queue.class.name
      assert_equal "SQSTestQueue", Ingest::FooIngest::BazWorker.queue.class.name
    end

    context "Worker::Ingest::Base" do
      setup do
        @ingest = FactoryGirl.create(:media_ingest_as_audio)
      end

      should "#perform_async" do
        assert_difference "Ingest::Worker.count" do
          result = Ingest::BarWorker.perform_async(ingest_id: @ingest.id)
          assert_equal({ingest_id: @ingest.id, worker_id: Ingest::Worker.sort_order("id" => "asc").last.id}.to_json, result)
        end
      end

      should "#perform_later" do
        assert_difference "Ingest::Worker.count" do
          result = Ingest::BarWorker.perform_later(ingest_id: @ingest.id)
          assert_equal({ingest_id: @ingest.id, worker_id: Ingest::Worker.sort_order("id" => "asc").last.id}.to_json, result)
        end
      end

      should "#perform_workflow" do
        assert_difference "Ingest::Worker.count" do
          result = Ingest::BarWorker.perform_workflow(ingest_id: @ingest.id)
          assert_equal({workflow: true, ingest_id: @ingest.id, worker_id: Ingest::Worker.sort_order("id" => "asc").last.id}.to_json, result)
        end
      end
    end
  end
end
