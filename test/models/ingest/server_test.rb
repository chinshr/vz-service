require 'test_helper'
require "#{Rails.root}/app/models/ingest/process"

class Ingest::ServerTest < ActiveSupport::TestCase
  context "associations" do
    should have_many(:processes).dependent(:destroy)
    should have_many(:ingests).through(:processes)

    context "delete ingests" do
      setup do
        @ingest = FactoryGirl.create(:media_ingest_as_audio)
        @server = FactoryGirl.create(:cpw_ingest_server)
      end

      should "ingest process through server" do
        assert_difference "Ingest::Process.count", 2 do
          @server.ingests << @ingest
          @server.ingests << FactoryGirl.create(:media_ingest_as_audio)
        end
        assert_equal 2, @server.processes.count
        assert_no_difference "Ingest.count" do
          assert_difference "Ingest::Process.count", -1 do
            @server.ingests.delete(@ingest)
            assert_equal 1, @server.processes.count
          end
        end
      end

      should "ingest process through ingest" do
        assert_difference "Ingest::Process.count" do
          @ingest.servers << @server
        end
        assert_no_difference "Ingest::Server.count" do
          assert_difference "Ingest::Process.count", -1 do
            @ingest.servers.delete(@server)
          end
        end
      end
    end
  end

  context "validations" do
    should validate_numericality_of :max_processes
  end

  should "create CPW server" do
    assert_difference "Ingest::Server::CPWServer.count" do
      server = FactoryGirl.create(:cpw_ingest_server)
      assert_equal 5, server.uid.length
    end
  end

  context "class" do
    should "have next_number" do
      assert_equal 1, Ingest::Server::CPWServer.next_number
      FactoryGirl.create(:cpw_ingest_server)
      assert_equal 2, Ingest::Server::CPWServer.next_number
    end

    should "calculate max_processes_from" do
      # foobar
      assert_equal 1, Ingest::Server.max_processes_from('foobar')
      # t2
      assert_equal 2, Ingest::Server.max_processes_from('t2.micro')
      assert_equal 2, Ingest::Server.max_processes_from('t2.small')
      assert_equal 4, Ingest::Server.max_processes_from('t2.medium')
      assert_equal 6, Ingest::Server.max_processes_from('t2.large')
      # m3
      assert_equal 20, Ingest::Server.max_processes_from('m3.xlarge')
    end

    context "create_from" do
      should "create server" do
        aws_ec2_instance = mock("AWS::EC2::Instance")
        aws_ec2_instance.expects(:id).returns("xyz")
        aws_ec2_instance.expects(:vpc_id).returns("vpc1")
        aws_ec2_instance.expects(:public_ip_address).returns("57.12.54.12")
        aws_ec2_instance.expects(:private_ip_address).returns("10.1.1.123")
        aws_ec2_instance.expects(:launch_time).returns(Time.zone.now)
        aws_ec2_instance.expects(:image_id).returns("ami-8fcbb0ea")
        aws_ec2_instance.expects(:instance_type).returns("m3.medium")

        assert_difference "Ingest::Server::CPWServer.count" do
          server = Ingest::Server::CPWServer.create_from(aws_ec2_instance)
          assert_equal "xyz", server.instance_id
          assert_equal "vpc1", server.vpc_id
          assert_equal "57.12.54.12", server.public_ip_address
          assert_equal "10.1.1.123", server.private_ip_address
          assert_equal "ami-8fcbb0ea", server.image_id
          assert_equal "m3.medium", server.instance_type
          assert_equal 1, server.number
          assert_equal 8, server.max_processes
        end
      end
    end
  end

  should "return status" do
    Provider::AWS::EC2.any_instance.stubs(:instance).returns(Struct.new(:status).new(:running))
    server = FactoryGirl.create(:cpw_ingest_server)
    assert_equal :running, server.status
  end

  context "restart" do
    should "enqueue _restart" do
      server = FactoryGirl.create(:cpw_ingest_server)
      assert_enqueued_with(job: Ingest::Server::RestartJob) do
        server.restart
      end
    end

    should "keep running when running" do
      instance_class = mock("AWS::EC2::Instance")
      instance_class.stubs(:status).returns(:running)
      Provider::AWS::EC2.any_instance.stubs(:instance).returns(instance_class)
      server = FactoryGirl.create(:cpw_ingest_server)
      assert_equal true, server.send(:_restart)
    end

    should "start instance when stopped" do
      instance_class = mock("AWS::EC2::Instance")
      instance_class.stubs(:status).returns(:stopped)
      instance_class.expects(:start)
      Provider::AWS::EC2.any_instance.stubs(:instance).returns(instance_class)
      server = FactoryGirl.create(:cpw_ingest_server)
      assert_equal true, server.send(:_restart)
    end

    should "not restart when terminated" do
      instance_class = mock("AWS::EC2::Instance")
      instance_class.stubs(:status).returns(:terminated)
      Provider::AWS::EC2.any_instance.stubs(:instance).returns(instance_class)
      server = FactoryGirl.create(:cpw_ingest_server)
      assert_equal false, server.send(:_restart)
    end

    should "not restart when shutting down" do
      instance_class = mock("AWS::EC2::Instance")
      instance_class.stubs(:status).returns(:shutting_down)
      Provider::AWS::EC2.any_instance.stubs(:instance).returns(instance_class)
      server = FactoryGirl.create(:cpw_ingest_server)
      assert_equal false, server.send(:_restart)
    end

    should "start instance when stopping" do
      instance_class = mock("AWS::EC2::Instance")
      instance_class.stubs(:status).returns(:stopping).then.returns(:stopped)
      instance_class.expects(:start)
      Provider::AWS::EC2.any_instance.stubs(:instance).returns(instance_class)
      server = FactoryGirl.create(:cpw_ingest_server)
      server.expects(:wait_until).with(:stopped)
      assert_equal true, server.send(:_restart)
    end
  end

  context "stop" do
    should "enqueue _stop" do
      server = FactoryGirl.create(:cpw_ingest_server)
      assert_enqueued_with(job: Ingest::Server::StopJob) do
        server.stop
      end
    end

    should "stop instance when running" do
      instance_class = mock("AWS::EC2::Instance")
      instance_class.stubs(:status).returns(:running)
      instance_class.expects(:stop)
      Provider::AWS::EC2.any_instance.stubs(:instance).returns(instance_class)
      server = FactoryGirl.create(:cpw_ingest_server)
      assert_equal true, server.send(:_stop)
    end

    should "stop instance when pending" do
      instance_class = mock("AWS::EC2::Instance")
      instance_class.stubs(:status).returns(:pending).then.returns(:running)
      instance_class.expects(:stop)
      Provider::AWS::EC2.any_instance.stubs(:instance).returns(instance_class)
      server = FactoryGirl.create(:cpw_ingest_server)
      server.expects(:wait_until).with(:running)
      assert_equal true, server.send(:_stop)
    end

    should "keep stopped when stopped" do
      instance_class = mock("AWS::EC2::Instance")
      instance_class.stubs(:status).returns(:stopped)
      Provider::AWS::EC2.any_instance.stubs(:instance).returns(instance_class)
      server = FactoryGirl.create(:cpw_ingest_server)
      assert_equal true, server.send(:_stop)
    end

    should "keep stopping when stopping" do
      instance_class = mock("AWS::EC2::Instance")
      instance_class.stubs(:status).returns(:stopped)
      Provider::AWS::EC2.any_instance.stubs(:instance).returns(instance_class)
      server = FactoryGirl.create(:cpw_ingest_server)
      assert_equal true, server.send(:_stop)
    end

    should "not stop when terminated" do
      instance_class = mock("AWS::EC2::Instance")
      instance_class.stubs(:status).returns(:terminated)
      Provider::AWS::EC2.any_instance.stubs(:instance).returns(instance_class)
      server = FactoryGirl.create(:cpw_ingest_server)
      assert_equal false, server.send(:_restart)
    end

    should "not stop when shutting down" do
      instance_class = mock("AWS::EC2::Instance")
      instance_class.stubs(:status).returns(:shutting_down)
      Provider::AWS::EC2.any_instance.stubs(:instance).returns(instance_class)
      server = FactoryGirl.create(:cpw_ingest_server)
      assert_equal false, server.send(:_restart)
    end
  end

  context "terminate" do
    should "enqueue _terminate" do
      server = FactoryGirl.create(:cpw_ingest_server)
      assert_enqueued_with(job: Ingest::Server::TerminateJob) do
        server.terminate
      end
    end

    should "terminate instance when running" do
      instance_class = mock("AWS::EC2::Instance")
      instance_class.stubs(:status).returns(:running)
      instance_class.expects(:terminate)
      Provider::AWS::EC2.any_instance.stubs(:instance).returns(instance_class)
      server = FactoryGirl.create(:cpw_ingest_server)
      assert_equal true, server.send(:_terminate)
    end

    should "terminate instance when pending" do
      instance_class = mock("AWS::EC2::Instance")
      instance_class.stubs(:status).returns(:pending).then.returns(:running)
      instance_class.expects(:terminate)
      Provider::AWS::EC2.any_instance.stubs(:instance).returns(instance_class)
      server = FactoryGirl.create(:cpw_ingest_server)
      server.expects(:wait_until).with(:running)
      assert_equal true, server.send(:_terminate)
    end

    should "keep terminated when terminate" do
      instance_class = mock("AWS::EC2::Instance")
      instance_class.stubs(:status).returns(:terminated)
      Provider::AWS::EC2.any_instance.stubs(:instance).returns(instance_class)
      server = FactoryGirl.create(:cpw_ingest_server)
      assert_equal true, server.send(:_terminate)
    end

    should "terminate instance when stopping" do
      instance_class = mock("AWS::EC2::Instance")
      instance_class.stubs(:status).returns(:stopping).then.returns(:stopped)
      instance_class.expects(:terminate)
      Provider::AWS::EC2.any_instance.stubs(:instance).returns(instance_class)
      server = FactoryGirl.create(:cpw_ingest_server)
      server.expects(:wait_until).with(:stopped)
      assert_equal true, server.send(:_terminate)
    end
  end

  should "destroy and terminate" do
    # instance_class = mock("AWS::EC2::Instance")
    # instance_class.stubs(:status).returns(:terminated)
    # Provider::AWS::EC2.any_instance.stubs(:instance).returns(instance_class)
    server = FactoryGirl.create(:cpw_ingest_server)
    server.expects(:terminate)
    assert_difference "Ingest::Server::CPWServer.count", -1 do
      server.destroy
    end
  end

  context "scopes" do
    context "state machine" do
      should "#pending" do
        server = FactoryGirl.create(:cpw_ingest_server, aasm_state: "pending")
        assert_equal server, Ingest::Server.pending.first
      end

      should "#enabled" do
        server = FactoryGirl.create(:cpw_ingest_server, aasm_state: "enabled")
        assert_equal server, Ingest::Server.enabled.first
      end

      should "#disabled" do
        server = FactoryGirl.create(:cpw_ingest_server, aasm_state: "disabled")
        assert_equal server, Ingest::Server.disabled.first
      end
    end

    context "#with_tenancy" do
      should "find with :private" do
        server = FactoryGirl.create(:cpw_ingest_server, tenancy: "private")
        assert_equal server, Ingest::Server.with_tenancy(:private).first
      end
    end

    context "#without_processes" do
      should "be empty" do
        assert_nil Ingest::Server.without_processes.first
      end

      should "find server without processes" do
        server = FactoryGirl.create(:cpw_ingest_server, max_processes: 1, aasm_state: "enabled")
        assert_equal server, Ingest::Server.without_processes.first
      end

      should "not find server without processes" do
        server = FactoryGirl.create(:cpw_ingest_server, max_processes: 1, aasm_state: "enabled")
        server.ingests << FactoryGirl.create(:media_ingest_as_audio)
        assert_equal nil, Ingest::Server.without_processes.first
      end

      should "find server with deleted processes" do
        server = FactoryGirl.create(:cpw_ingest_server, max_processes: 1, aasm_state: "enabled")
        ingest = FactoryGirl.create(:media_ingest_as_audio)
        server.ingests << ingest
        server.ingests.delete(ingest)
        assert_equal server, Ingest::Server.without_processes.first
      end

    end

    context "#available" do
      should "be empty" do
        assert_nil Ingest::Server.available.first
      end

      should "be available when enabled and without consumption" do
        server = FactoryGirl.create(:cpw_ingest_server, max_processes: 1, aasm_state: "enabled")
        assert_equal server, Ingest::Server.available.first
      end

      should "not be available when pending" do
        server = FactoryGirl.create(:cpw_ingest_server, max_processes: 1, aasm_state: "pending")
        assert_nil Ingest::Server.available.first
      end

      should "not be available when disabled" do
        server = FactoryGirl.create(:cpw_ingest_server, max_processes: 1, aasm_state: "disabled")
        assert_nil Ingest::Server.available.first
      end

      should "be consumed for 1 ingest" do
        server = FactoryGirl.create(:cpw_ingest_server, max_processes: 1, aasm_state: "enabled")
        ingest = FactoryGirl.create(:media_ingest_as_audio)
        server.ingests << ingest
        assert_nil Ingest::Server.available.first
      end

      should "be consumed for 2 ingests" do
        server = FactoryGirl.create(:cpw_ingest_server, max_processes: 2, aasm_state: "enabled")
        ingest1 = FactoryGirl.create(:media_ingest_as_audio)
        ingest2 = FactoryGirl.create(:media_ingest_as_audio)
        server.ingests << ingest1
        assert_equal server, Ingest::Server.available.first
        server.ingests << ingest2
        assert_nil Ingest::Server.available.first
      end
    end
  end

  should "stop server when last ingest is removed" do
    @ingest = FactoryGirl.create(:media_ingest_as_audio)
    @server = FactoryGirl.create(:cpw_ingest_server)
    @server.ingests << @ingest
    assert_difference "Ingest::Process.count", -1 do
      assert_enqueued_with(job: Ingest::Server::StopJob) do
        @server.ingests.delete(@ingest)
      end
    end
  end

  context "state machine" do

    should "transition" do
      @server = FactoryGirl.create(:cpw_ingest_server)
      assert_equal :pending, @server.state
      assert_equal true, @server.enable!
      assert_equal :enabled, @server.state
      assert_not_nil @server.enabled_at
      assert_equal true, @server.disable!
      assert_equal :disabled, @server.state
      assert_not_nil @server.disabled_at
    end

    should "not transition" do
      @server = FactoryGirl.create(:cpw_ingest_server, aasm_state: "disabled")
      assert_equal :disabled, @server.state
      assert_raise AASM::InvalidTransition do
        assert_equal false, @server.enable!
      end
    end

  end
end
