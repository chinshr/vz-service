require 'test_helper'

class Api::ClientAccessTest < ActiveSupport::TestCase
  context "associations" do
    should belong_to(:client)
    should belong_to(:user)
    should have_many(:clients)

    should "successfully create client_access with device as the join model" do
      client_access = FactoryGirl.create(:client_access)
      client_access.device_uid = '1234567'
      client_access.clients.create(name: 'client_name', key: Api::Client::generate_key)
      assert_equal 1, client_access.devices.size
      @device = client_access.devices.first
      assert_equal '1234567', @device.uid
      assert_equal 1, client_access.clients.size
      @client = client_access.clients.first
      assert_equal 'client_name', @client.name
      assert_equal [@device], @client.devices
    end

    should "create client_access and associate with an existing device with the same device uid" do
      client_access = FactoryGirl.create(:client_access)
      device = FactoryGirl.create(:device, :uid => '1234567', :client => FactoryGirl.create(:client, :name => 'old_client_name'))
      client_access.device_uid = '1234567'
      client_access.clients.create(:name => 'client_name', :key => Api::Client::generate_key)
      assert_equal 1, client_access.devices.size
      @device = client_access.devices.first
      assert_equal '1234567', @device.uid
      assert_equal 1, client_access.clients.size
      @client = client_access.clients.first
      assert_equal 'old_client_name', @client.name
      assert_equal [@device], @client.devices
    end
  end

  should "generate random secret" do
    client_access = FactoryGirl.build_stubbed(:client_access)
    client_access.access_secret = "123456"
    client_access.generate_secret
    assert_equal false, client_access.access_secret == "123456"
  end

  context "state machine" do
    setup do
      @active   = FactoryGirl.create(:client_access, aasm_state: "active")
      @inactive = FactoryGirl.create(:client_access, aasm_state: "inactive")
    end

    should "transition from active to inactive" do
      @active.deactivate!
      assert_equal false, @active.active?
      assert_not_nil @active.deactivated_at
    end

    should "transition from inactive to active" do
      @inactive.activate!
      assert_equal true, @inactive.active?
      assert_not_nil @inactive.activated_at
    end
  end
end
