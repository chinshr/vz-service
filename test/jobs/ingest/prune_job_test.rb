require 'test_helper'

class Ingest::PruneJobTest < ActiveSupport::TestCase

  context "stale 'starting' ingests" do
    should "stop 'stale' ingests" do
      ingest = FactoryGirl.create(:media_ingest_as_audio,
        aasm_state: "starting", created_at: Time.zone.now - 2.hours - 1.second)
      Ingest::PruneJob.new.perform
      ingest.reload
      assert_equal :stopped, ingest.state
    end

    should "not stop ingests that are not quite stale yet" do
      ingest = FactoryGirl.create(:media_ingest_as_audio,
        aasm_state: "starting", created_at: Time.zone.now - 10.minutes)
      Ingest::PruneJob.new.perform
      ingest.reload
      assert_equal :starting, ingest.state
    end
  end
=begin
  context "delete removed ingests" do
    should "delete removed older than X" do
      ingest = FactoryGirl.create(:media_ingest_as_audio,
        aasm_state: "removed", removed_at: Time.zone.now - 30.days - 1.second)
      assert_enqueued_with(job: Ingest::DeleteJob) do
        Ingest::PruneJob.new.perform
      end
    end

    should "NOT delete removed younger than X" do
      ingest = FactoryGirl.create(:media_ingest_as_audio,
        aasm_state: "removed", removed_at: Time.zone.now - 29.days)
      assert_no_enqueued_jobs do
        Ingest::PruneJob.new.perform
      end
    end
  end
=end
  context "terminate 'stale' servers" do
    should "terminate instance" do
      server = FactoryGirl.create(:cpw_ingest_server, aasm_state: "enabled", enabled_at: Time.zone.now - 24.hours)
      Ingest::Server.any_instance.expects(:terminate).returns(true)
      Ingest::PruneJob.new.perform
    end

    should "not terminate instance" do
      server = FactoryGirl.create(:cpw_ingest_server, aasm_state: "enabled", enabled_at: Time.zone.now - 59.minutes)
      Ingest::Server.any_instance.expects(:terminate).never
      Ingest::PruneJob.new.perform
    end
  end
end