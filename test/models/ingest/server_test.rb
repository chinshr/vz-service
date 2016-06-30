require 'test_helper'

class Ingest::ServerTest < ActiveSupport::TestCase
  context "associations" do
    should have_many(:workers)
    should have_many(:ingests).through(:workers)

    should "have_many uniq ingests" do
      ingest = FactoryGirl.create(:media_ingest_as_audio)
      server = FactoryGirl.create(:cpw_ingest_server)
      w1 = FactoryGirl.create(:ingest_worker, server: server, ingest: ingest)
      w2 = FactoryGirl.create(:ingest_worker, server: server, ingest: ingest)
      w3 = FactoryGirl.create(:ingest_worker, server: server, ingest: ingest)
      assert_equal 1, server.ingests.to_a.size
    end
  end

  context "validations" do
    should validate_numericality_of :max_workers
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

    should "calculate max_workers_from" do
      # foobar
      assert_equal 1, Ingest::Server.max_workers_from('foobar')
      # t2
      assert_equal 2, Ingest::Server.max_workers_from('t2.micro')
      assert_equal 2, Ingest::Server.max_workers_from('t2.small')
      assert_equal 4, Ingest::Server.max_workers_from('t2.medium')
      assert_equal 6, Ingest::Server.max_workers_from('t2.large')
      # m3
      assert_equal 20, Ingest::Server.max_workers_from('m3.xlarge')
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
        aws_ec2_instance.expects(:status).returns(:running)

        assert_difference "Ingest::Server::CPWServer.count" do
          server = Ingest::Server::CPWServer.create_from(aws_ec2_instance)
          assert_equal "xyz", server.instance_id
          assert_equal "vpc1", server.vpc_id
          assert_equal "57.12.54.12", server.public_ip_address
          assert_equal "10.1.1.123", server.private_ip_address
          assert_equal "ami-8fcbb0ea", server.image_id
          assert_equal "m3.medium", server.instance_type
          assert_equal 1, server.number
          assert_equal 8, server.max_workers
          assert_equal :enabled, server.state
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
      instance_class.stubs(:launch_time).returns(Time.zone.now)
      Provider::AWS::EC2.any_instance.stubs(:instance).returns(instance_class)
      server = FactoryGirl.create(:cpw_ingest_server)
      assert_equal true, server.send(:_restart)
    end

    should "start instance when stopped" do
      instance_class = mock("AWS::EC2::Instance")
      instance_class.stubs(:status).returns(:stopped)
      instance_class.expects(:start)
      instance_class.stubs(:launch_time).returns(Time.zone.now)
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
      instance_class.stubs(:launch_time).returns(Time.zone.now)
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
      #server.expects(:wait_until).with(:running)
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
      assert_equal :pending, server.state
      assert_enqueued_with(job: Ingest::Server::TerminateJob) do
        server.terminate
        assert_equal :disabled, server.state
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
      server.expects(:wait_until).with(:terminated)
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

  should "#with_busy_workers?" do
    server = FactoryGirl.create(:cpw_ingest_server)
    assert_equal false, server.with_busy_workers?
    FactoryGirl.create(:ingest_worker, :running, {server: server})
    assert_equal true, server.with_busy_workers?
  end

  should "#without_busy_workers?" do
    server = FactoryGirl.create(:cpw_ingest_server)
    assert_equal true, server.without_busy_workers?
    FactoryGirl.create(:ingest_worker, {server: server})
    assert_equal false, server.without_busy_workers?
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

    context "#without_workers" do
      should "be empty" do
        assert_nil Ingest::Server.without_workers.first
      end

      should "find server without workers" do
        server = FactoryGirl.create(:cpw_ingest_server, max_workers: 1, aasm_state: "enabled")
        assert_equal server, Ingest::Server.without_workers.first
      end

      should "not find server without workers" do
        server = FactoryGirl.create(:cpw_ingest_server, max_workers: 1, aasm_state: "enabled")
        worker = Ingest::Worker.create(worker_name: "foobar", ingest: FactoryGirl.create(:media_ingest_as_audio), server: server)
        assert_equal nil, Ingest::Server.without_workers.first
      end
    end

    context "#without_busy_workers" do
      should "be empty" do
        assert_nil Ingest::Server.without_busy_workers.first
      end

      should "find server without busy workers" do
        server = FactoryGirl.create(:cpw_ingest_server, max_workers: 1, aasm_state: "enabled")
        assert_equal server, Ingest::Server.without_busy_workers.first
      end

      should "not find server with 'created' workers" do
        server = FactoryGirl.create(:cpw_ingest_server, max_workers: 1, aasm_state: "enabled")
        worker = FactoryGirl.create(:ingest_worker, server: server)
        assert_equal nil, Ingest::Server.without_busy_workers.first
      end

      should "not find server with 'running' workers" do
        server = FactoryGirl.create(:cpw_ingest_server, max_workers: 1, aasm_state: "enabled")
        worker = FactoryGirl.create(:ingest_worker, :running, {server: server})
        assert_equal nil, Ingest::Server.without_busy_workers.first
      end

      should "find server with 'finished' workers" do
        server = FactoryGirl.create(:cpw_ingest_server, max_workers: 1, aasm_state: "enabled")
        worker = FactoryGirl.create(:ingest_worker, :finished, {server: server})
        assert_equal server, Ingest::Server.without_busy_workers.first
      end
    end

    context "#available" do
      should "be empty" do
        assert_nil Ingest::Server.available.first
      end

      should "be available when enabled and without consumption" do
        server = FactoryGirl.create(:cpw_ingest_server, max_workers: 1, aasm_state: "enabled")
        assert_equal server, Ingest::Server.available.first
      end

      should "not be available when pending" do
        server = FactoryGirl.create(:cpw_ingest_server, max_workers: 1, aasm_state: "pending")
        assert_nil Ingest::Server.available.first
      end

      should "not be available when disabled" do
        server = FactoryGirl.create(:cpw_ingest_server, max_workers: 1, aasm_state: "disabled")
        assert_nil Ingest::Server.available.first
      end

      should "be consumed for 1 worker" do
        server = FactoryGirl.create(:cpw_ingest_server, max_workers: 1, aasm_state: "enabled")
        ingest = FactoryGirl.create(:media_ingest_as_audio)
        worker = FactoryGirl.create(:ingest_worker, :running, server: server, ingest: ingest)
        assert_nil Ingest::Server.available.first
      end

      should "be consumed for 2 ingests" do
        server = FactoryGirl.create(:cpw_ingest_server, max_workers: 2, aasm_state: "enabled")
        ingest1 = FactoryGirl.create(:media_ingest_as_audio)
        ingest2 = FactoryGirl.create(:media_ingest_as_audio)

        assert_equal server, Ingest::Server.available.first
        FactoryGirl.create(:ingest_worker, :running, server: server, ingest: ingest1)
        assert_equal server, Ingest::Server.available.first
        FactoryGirl.create(:ingest_worker, :finished, server: server, ingest: ingest1)
        assert_equal server, Ingest::Server.available.first
        FactoryGirl.create(:ingest_worker, :running, server: server, ingest: ingest2)
        assert_nil Ingest::Server.available.first
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

    should "update enabled_at when already enabled" do
      @server = FactoryGirl.create(:cpw_ingest_server, :enabled, enabled_at: Time.zone.now - 1.day)
      assert_equal true, @server.enable!
      assert_in_delta Time.zone.now, @server.enabled_at, 1.second
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
