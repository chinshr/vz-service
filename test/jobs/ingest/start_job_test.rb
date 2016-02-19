require 'test_helper'

class Ingest::StartJobTest < ActiveSupport::TestCase

  should "start instance" do
    ingest = FactoryGirl.create(:media_ingest_as_audio)

    assert_difference "Ingest::Server::CPWServer.count" do
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

      Ingest::StartJob.new.perform(ingest.id)
      assert_equal 1, ingest.servers.count
    end
  end

end