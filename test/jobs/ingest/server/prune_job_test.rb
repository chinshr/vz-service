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
      @worker = FactoryGirl.create(:ingest_worker, :running, ingest: @ingest)
    end

    context "servers enabled almost 1 hour ago" do
      should "stop without busy workers" do
        server = FactoryGirl.create(:cpw_ingest_server, :enabled, enabled_at: Time.zone.now - 55.minutes)
        @worker.update_attributes(server: server)
        @worker.finish!
        assert_enqueued_with(job: Ingest::Server::StopJob, args:[server.id]) do
          Ingest::Server::PruneJob.new.perform
        end
      end

      should "don't stop with busy workers" do
        server = FactoryGirl.create(:cpw_ingest_server, :enabled, enabled_at: Time.zone.now - 55.minutes)
        @worker.update_attributes(server: server)
        assert_enqueued_jobs 0 do
          Ingest::Server::PruneJob.new.perform
        end
      end
    end

    should "stop servers with stopped workers" do
      server = FactoryGirl.create(:cpw_ingest_server, :enabled, enabled_at: Time.zone.now - 1.hour)
      worker = FactoryGirl.create(:ingest_worker, :stopped, {ingest: @ingest, server: server})
      assert_enqueued_with(job: Ingest::Server::StopJob, args:[server.id]) do
        Ingest::Server::PruneJob.new.perform
      end
    end

    should "not stop 'recently' launched servers" do
      server = FactoryGirl.create(:cpw_ingest_server, :enabled, enabled_at: Time.zone.now - 54.minutes)
      assert_equal [server].to_set, Ingest::Server.enabled.without_busy_workers.to_set
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
      worker = FactoryGirl.create(:ingest_worker, server: server)
      Ingest::Server.any_instance.expects(:terminate).never
      Ingest::Server::PruneJob.new.perform
    end

    should "terminate stale servers with no busy workers" do
      server = FactoryGirl.create(:cpw_ingest_server, :enabled, enabled_at: Time.zone.now - 8.hours - 1.minute)
      worker = FactoryGirl.create(:ingest_worker, :finished, {ingest: @ingest, server: server})
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
