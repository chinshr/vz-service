require 'test_helper'

class Api::ClientTest < ActiveSupport::TestCase
  context "associations" do
    should have_many(:devices)
    should have_many(:client_accesses)#.through(:devices)
  end

  context "validations" do
    subject { FactoryGirl.create(:client) }

    should validate_presence_of(:name)
    should validate_uniqueness_of(:name)
    should validate_length_of(:name).is_at_least(1).is_at_most(250)
  end

  should "generate key" do
    assert_not_nil Api::Client.generate_key
  end

  should "create client" do
    assert_difference 'Api::Client.count' do
      client = Api::Client.find_or_create_by(name: "CPW")
      client.key ||= "bC3gpycUkRf9gDrdFVUdtyqTiaJzKSf4ujVMXtxi3Mzr"
      client.save!
      assert_equal "bC3gpycUkRf9gDrdFVUdtyqTiaJzKSf4ujVMXtxi3Mzr", client.reload.key
    end
  end
end
