require 'test_helper'

class Ingest::BarWorker < Worker::Base; end
module Ingest::FooIngest; end
class Ingest::FooIngest::BazWorker < Worker::Base; end

class Worker::BaseTest < ActiveSupport::TestCase

  context "class" do
    setup do
      Worker::Base.queues = {}
    end

    should "#queue_name" do
      assert_equal "INGEST_BAR_TEST_QUEUE", Ingest::BarWorker.queue_name
      assert_equal "INGEST_FOO_INGEST_BAZ_TEST_QUEUE", Ingest::FooIngest::BazWorker.queue_name
    end

    should "provide queue" do
      assert_equal "SQSTestQueue", Ingest::BarWorker.queue.class.name
      assert_equal "SQSTestQueue", Ingest::FooIngest::BazWorker.queue.class.name
    end

    should "#perform_async" do
      result = Ingest::BarWorker.perform_async(ingest_id: 1)
      assert_equal({ingest_id: 1}.to_json, result)
    end

    should "#perform_later" do
      result = Ingest::BarWorker.perform_later(ingest_id: 1)
      assert_equal({ingest_id: 1}.to_json, result)
    end

    should "#perform_workflow" do
      result = Ingest::BarWorker.perform_workflow(ingest_id: 1)
      assert_equal({workflow: true, ingest_id: 1}.to_json, result)
    end
  end
end
