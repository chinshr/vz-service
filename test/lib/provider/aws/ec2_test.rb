require 'test_helper'

class Provider::AWS::EC2Test < ActiveSupport::TestCase
  should "instantiate" do
    ec2 = Provider::AWS::EC2.new
  end
end