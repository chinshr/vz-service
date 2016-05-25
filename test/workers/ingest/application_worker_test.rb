require 'test_helper'

class Ingest::MediaIngest::FooWorker < Ingest::ApplicationWorker; end

class Ingest::ApplicationWorkerTest < ActiveSupport::TestCase

  context "class" do
    setup do
      Ingest::ApplicationWorker.queues = {}
    end

    should "#queue_name" do
      assert_equal "INGEST_MEDIA_INGEST_FOO_TEST_QUEUE", Ingest::MediaIngest::FooWorker.queue_name
    end

    should "#perform_async" do
      result = Ingest::MediaIngest::FooWorker.perform_async(1)
      assert_equal({ingest_id: 1}.to_json, result)
    end

    should "#perform_later" do
      result = Ingest::MediaIngest::FooWorker.perform_later(1)
      assert_equal({ingest_id: 1}.to_json, result)
    end

    should "#perform_workflow" do
      result = Ingest::MediaIngest::FooWorker.perform_workflow(1)
      assert_equal({ingest_id: 1, workflow: true}.to_json, result)
    end
  end
end
