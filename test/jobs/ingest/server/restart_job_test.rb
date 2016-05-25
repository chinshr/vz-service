require 'test_helper'

class Ingest::Server::RestartJobTest < ActiveSupport::TestCase

  context "with server_id" do
    setup do
      @server = FactoryGirl.create(:cpw_ingest_server)
    end

    should "start instance" do
      Ingest::Server.any_instance.expects(:_restart).returns(true)
      Ingest::Server::RestartJob.new.perform(@server.id)
    end

    should "start a new server instance if requested one is not responding" do
      assert_equal true, @server.disable!
      aws_ec2_instance = mock("AWS::EC2::Instance")
      aws_ec2_instance.expects(:status).returns(:running)
      Ingest::Server.any_instance.stubs(:instance).returns(aws_ec2_instance)
      assert_enqueued_with(job: Ingest::Server::RestartJob) do
        Ingest::Server::RestartJob.new.perform(@server.id)
      end
    end

  end

  context "without server_id" do
    setup do
      @server = FactoryGirl.create(:cpw_ingest_server)
    end

    should "creates new server and new instance" do
      assert_equal :pending, @server.state
      aws_ec2_instance = mock("AWS::EC2::Instance")
      aws_ec2_instance.expects(:id).returns("xyz")
      aws_ec2_instance.expects(:vpc_id).returns("vpc1")
      aws_ec2_instance.expects(:public_ip_address).returns("57.12.54.12")
      aws_ec2_instance.expects(:private_ip_address).returns("10.1.1.123")
      aws_ec2_instance.expects(:launch_time).returns(Time.zone.now)
      aws_ec2_instance.expects(:image_id).returns("ami-8fcbb0ea")
      aws_ec2_instance.expects(:instance_type).returns("t2.micro")
      aws_ec2_instance.expects(:status).returns(:pending)
      Provider::AWS::EC2.any_instance.stubs(:launch).returns(aws_ec2_instance)
      Ingest::Server.any_instance.expects(:_restart).returns(true)
      assert_difference "Ingest::Server.count", 1 do
        Ingest::Server::RestartJob.new.perform
      end
    end

    should "use existing server and restarts instance" do
      assert_equal true, @server.enable!
      Ingest::Server.any_instance.expects(:_restart).returns(true)
      assert_no_difference "Ingest::Server.count" do
        Ingest::Server::RestartJob.new.perform
      end
    end
  end

end