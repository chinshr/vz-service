require 'test_helper'

class Ingest::Server::PruneJobTest < ActiveSupport::TestCase

  setup do
    AWS::EC2::Instance.any_instance.stubs(:status).returns(:running)
  end

  context "#destroy" do
    should "destroy disabled server" do
      server = FactoryGirl.create(:cpw_ingest_server, :disabled, disabled_at: Time.zone.now - 2.days)
      assert_difference "Ingest::Server.count", -1 do
        Ingest::Server::PruneJob.new.perform
      end
    end

    should "not destroy disabled server" do
      server = FactoryGirl.create(:cpw_ingest_server, :disabled, disabled_at: Time.zone.now - 59.minutes)
      assert_no_difference "Ingest::Server.count" do
        Ingest::Server::PruneJob.new.perform
      end
    end
  end

  context "#sync" do
    setup do
      AWS::EC2::Instance.any_instance.stubs(:status).returns(:terminated)
    end

    should "terminate enabled server when terminated" do
      server = FactoryGirl.create(:cpw_ingest_server, :enabled)
      Ingest::Server::PruneJob.new.perform
      assert_equal :disabled, server.reload.state
    end
  end

  context "#stop" do
    setup do
      @ingest = FactoryGirl.create(:media_ingest_as_audio)
    end

    should "stop server without ingests" do
      server = FactoryGirl.create(:cpw_ingest_server, :enabled, enabled_at: Time.zone.now - 16.minutes)
      assert_enqueued_with(job: Ingest::Server::StopJob, args:[server.id]) do
        Ingest::Server::PruneJob.new.perform
      end
    end

    should "not stop servers with running ingests" do
      server = FactoryGirl.create(:cpw_ingest_server, :enabled, enabled_at: Time.zone.now - 16.minutes)
      server.ingests << @ingest
      Ingest::Server.any_instance.expects(:stop).never
    end

    should "stop servers with removed ingests" do
      server = FactoryGirl.create(:cpw_ingest_server, :enabled, enabled_at: Time.zone.now - 1.hour)
      @ingest.remove! and @ingest.process!
      assert_equal :removed, @ingest.state
      server.ingests << @ingest
      assert_enqueued_with(job: Ingest::Server::StopJob, args:[server.id]) do
        Ingest::Server::PruneJob.new.perform
      end
    end

    should "not stop recently launched servers" do
      server = FactoryGirl.create(:cpw_ingest_server, :enabled, enabled_at: Time.zone.now - 1.minutes)
      Ingest::Server.any_instance.expects(:stop).never
      Ingest::Server::PruneJob.new.perform
    end

  end

  context "#terminate" do
    setup do
      @ingest = FactoryGirl.create(:media_ingest_as_audio)
    end

    should "terminate stale servers without ingests" do
      server = FactoryGirl.create(:cpw_ingest_server, :enabled, enabled_at: Time.zone.now - 8.hours - 1.minute)
      assert_enqueued_with(job: ::Ingest::Server::TerminateJob, args:[server.id]) do
        Ingest::Server::PruneJob.new.perform
      end
    end

    should "not terminate stale servers with ingests" do
      server = FactoryGirl.create(:cpw_ingest_server, :enabled, enabled_at: Time.zone.now - 8.hours - 1.minute)
      server.ingests << @ingest
      Ingest::Server.any_instance.expects(:terminate).never
    end

    should "terminate stale servers with removed ingests" do
      server = FactoryGirl.create(:cpw_ingest_server, :enabled, enabled_at: Time.zone.now - 8.hours - 1.minute)
      @ingest.remove! && @ingest.process!
      assert_equal :removed, @ingest.state
      server.ingests << @ingest
      assert_enqueued_with(job: ::Ingest::Server::TerminateJob, args:[server.id]) do
        Ingest::Server::PruneJob.new.perform
      end
    end

    should "not terminate recently enabled servers" do
      server = FactoryGirl.create(:cpw_ingest_server, :enabled, enabled_at: Time.zone.now - 59.minutes)
      Ingest::Server.any_instance.expects(:terminate).never
      Ingest::Server::PruneJob.new.perform
    end

  end
end
