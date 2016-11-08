require 'test_helper'

class Ingest::Worker::PruneJobTest < ActiveSupport::TestCase
  context "#stop_stale_workers" do

    should "terminate worker created more than 3 hours ago" do
      server = FactoryGirl.create(:cpw_ingest_server, :enabled, enabled_at: Time.zone.now - 8.hours - 1.minute)
      worker = FactoryGirl.create(:ingest_worker, :running, server: server, started_at: Time.zone.now - 3.hours - 1.second)

      assert_equal :running, worker.state
      Ingest::Worker::PruneJob.new.perform
      assert_equal :stopped, worker.reload.state
    end

    should "not terminate worker recently created" do
      server = FactoryGirl.create(:cpw_ingest_server, :enabled, enabled_at: Time.zone.now - 8.hours - 1.minute)
      worker = FactoryGirl.create(:ingest_worker, :running, server: server)

      assert_equal :running, worker.state
      Ingest::Worker::PruneJob.new.perform
      assert_equal :running, worker.reload.state
    end

  end
end
