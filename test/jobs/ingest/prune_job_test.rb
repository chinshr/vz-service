require 'test_helper'

class Ingest::PruneJobTest < ActiveSupport::TestCase

  context "stale ingests" do
    should "stop stale ingests" do
      ingest = FactoryGirl.create(:media_ingest_as_audio, created_at: Time.zone.now - 2.hours)
      Ingest::PruneJob.new.perform
      ingest.reload
      assert_equal :stopped, ingest.state
    end

    should "not stop ingests that are not quite stale yet" do
      ingest = FactoryGirl.create(:media_ingest_as_audio, created_at: Time.zone.now - 10.minutes)
      Ingest::PruneJob.new.perform
      ingest.reload
      assert_equal :starting, ingest.state
    end
  end

  context "stale servers" do
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