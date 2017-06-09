require 'test_helper'

class Api::DeviceTest < ActiveSupport::TestCase
  context "associations" do
    should belong_to(:client)
    should belong_to(:client_access)
  end

  context "validations" do
    subject { FactoryGirl.create(:device) }

    should validate_uniqueness_of(:uid)
    should validate_presence_of(:uid)
  end

  context "#device_name" do
    setup do
      @platform = FactoryGirl.create(:platform, :name => "Platform")
      @client   = FactoryGirl.create(:client, :platform => @platform)
      @user     = FactoryGirl.create(:user)
      @client_access = FactoryGirl.create(:client_access, :client => @client, :user => @user)
    end

    context "infer a humanized name from the platform when device_name is not given" do
      should "use amount of authroized devices with the same platform" do
        first_device = FactoryGirl.create(:device, :device_name => nil, :uid => SecureRandom.hex(20), :client_access => @client_access, :client => @client)
        assert_equal "platform-1", first_device.device_name
        second_device = FactoryGirl.create(:device, :device_name => nil, :uid => SecureRandom.hex(20), :client_access => @client_access, :client => @client)
        assert_equal "platform-2", second_device.device_name
      end
    end

    context "given a device_name" do
      should "create a device with the specified device_name" do
      end
    end
  end

  context "scopes" do
    context "#authorized" do
      setup do
        3.times { FactoryGirl.create(:device, :uid => SecureRandom.hex(20), :client_access => FactoryGirl.create(:client_access, :aasm_state => 'inactive'))}
        3.times { FactoryGirl.create(:device, :uid => SecureRandom.hex(20), :client_access => FactoryGirl.create(:client_access, :aasm_state => 'active'))}
      end

      should "return all the devices" do
        assert_equal 6, Api::Device.count
      end

      should "return only active devices" do
        assert_equal 3, Api::Device.authorized(true).count
      end

      should "return only inactive devices" do
        assert_equal 3, Api::Device.authorized(false).count
      end
    end

    context "#uid" do
      setup do
        3.times { FactoryGirl.create(:device, :uid => SecureRandom.hex(20), :client_access => FactoryGirl.create(:client_access, :aasm_state => 'active'))}
        @uid = SecureRandom.hex(20)
        @device = FactoryGirl.create(:device, :uid => @uid, :client_access => FactoryGirl.create(:client_access, :aasm_state => 'active'))
      end

      should "return the correct device with the correct uid" do
        assert_equal @device, Api::Device.uid(@uid).first
      end

      should "return nothing with incorrect uid" do
        assert_nil Api::Device.uid("foobarbaz").first
      end
    end

    context "#device_name" do
      setup do
        3.times { FactoryGirl.create(:device, :uid => SecureRandom.hex(20), :client_access => FactoryGirl.create(:client_access, :aasm_state => 'active'))}
        @uid = SecureRandom.hex(20)
        @device = FactoryGirl.create(:device, :uid => @uid, :client_access => FactoryGirl.create(:client_access, :aasm_state => 'active'), :device_name => 'foobar')
      end

      should "find by name" do
        assert_equal @device, Api::Device.device_name('foobar').first
      end
    end

    context "#any_of_user_ids" do
      setup do
        @user = FactoryGirl.create(:user)
        @other_user = FactoryGirl.create(:user)
        3.times { FactoryGirl.create(:device, :uid => SecureRandom.hex(20),
          :client_access => FactoryGirl.create(:client_access, :aasm_state => 'active', :user => FactoryGirl.create(:user)))}
        @uid = SecureRandom.hex(20)
        @device = FactoryGirl.create(:device, :uid => @uid, :client_access => FactoryGirl.create(:client_access, :aasm_state => 'active', :user => @user))
      end

      should "return only devices related to the specified user" do
        assert_equal @device, Api::Device.any_of_user_ids(@user.id).first
      end

      should "return nothing with incorrect user id" do
        assert_nil Api::Device.any_of_user_ids(@other_user.id).first
      end
    end

    context "#any_of_platform_ids" do
      setup do
        @platform_one  = FactoryGirl.create(:platform)
        @platform_two  = FactoryGirl.create(:platform)
        @first_client  = FactoryGirl.create(:client, :platform => @platform_one)
        @second_client = FactoryGirl.create(:client, :platform => @platform_two)
        3.times { FactoryGirl.create(:device, :uid => SecureRandom.hex(20), :client => @first_client, :client_access => FactoryGirl.create(:client_access, :aasm_state => 'active'))}
        @uid = SecureRandom.hex(20)
        @device = FactoryGirl.create(:device, :client => @second_client, :uid => @uid, :client_access => FactoryGirl.create(:client_access, :aasm_state => 'active'))
      end

      should "return the correct device with the selected platform" do
        assert_equal @device, Api::Device.any_of_platform_ids(@platform_two.id).first
      end

      should "return all the devices of the given platform ids" do
        assert_equal 4, Api::Device.any_of_platform_ids([@platform_one.id, @platform_two.id]).size
      end

      should "should return nothing with incorrect plaform id" do
        assert_nil Api::Device.any_of_platform_ids("-1").first
      end
    end
  end

  context "authorization" do
    setup do
      @user       = FactoryGirl.create(:user)
      @admin_user = FactoryGirl.create(:admin_user)
      @device     = FactoryGirl.create(:device, :client_access => FactoryGirl.create(:client_access, :aasm_state => 'inactive', :user => @user),
        :client => FactoryGirl.create(:client))
    end

    should "authorize successfully" do
      @device.authorize!
      assert_equal true, @device.authorized?
      assert_equal true, @device.authorized
    end

    should "deauthorize successfully" do
      @device.authorize!
      @device.deauthorize!
      assert_equal false, @device.authorized?
    end

    should "not authorize more devices than allowed under the platform cap limit of a user" do
      ENV.stubs(:[]).returns('30')
      client = FactoryGirl.create(:client, :platform => FactoryGirl.create(:platform, :cap => true))
      30.times { FactoryGirl.create(:device, :client_access => FactoryGirl.create(:client_access, :aasm_state => 'active', :user => @user),
        :client => client, :uid => SecureRandom.hex(20))}
      @device.client = client
      @device.save and @device.reload
      Timecop.freeze(Date.today + 1.month + 2.days) do
        assert_raise Api::Exception::DeviceLimit do
          @device.authorize!
        end
      end
    end

    should "authorize unlimited amount of devices with no platform cap" do
      ENV.stubs(:[]).returns('30')
      client = FactoryGirl.create(:client, :platform => FactoryGirl.create(:platform, :cap => true))
      30.times { FactoryGirl.create(:device, :client_access => FactoryGirl.create(:client_access, :aasm_state => 'active', :user => @user),
        :client => client, :uid => SecureRandom.hex(20))}
      non_capped_client = FactoryGirl.create(:client, :platform => FactoryGirl.create(:platform, :cap => false))
      @device.client = non_capped_client and @device.save and @device.reload
      Timecop.freeze(Date.today + 1.month + 2.days) do
        assert_nothing_raised do
          @device.authorize!
        end
      end
    end

    should "authorize device when number of activated devices is under the platform cap limit of an account" do
      ENV.stubs(:[]).returns('30')
      client = FactoryGirl.create(:client, :platform => FactoryGirl.create(:platform, :cap => true))
      10.times { FactoryGirl.create(:device, :client_access => FactoryGirl.create(:client_access, :aasm_state => 'active', :user => @user),
        :client => client, :uid => SecureRandom.hex(20))}
      @device.client = client and @device.save and @device.reload
      Timecop.freeze(Date.today + 1.month + 2.days) do
        assert_nothing_raised do
          @device.authorize!
        end
      end
    end
  end
end
