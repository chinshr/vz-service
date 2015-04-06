require 'test_helper'

class Api::PlatformTest < ActiveSupport::TestCase
  context "associations" do
    should have_many(:clients)
  end

  context "validations" do
    subject { FactoryGirl.create(:platform) }

    should validate_uniqueness_of(:name).scoped_to(:version)
    should validate_presence_of(:name)
    should validate_presence_of(:version)
  end

  should "create platform" do
    assert_difference "Api::Platform.count" do
      platform = Api::Platform.create(name: "test-platform-1", version: "1.0")
      assert_equal "test-platform-1", platform.name
      assert_not_nil platform.uid
    end
  end

  should "create platform with custom UID" do
    assert_difference "Api::Platform.count" do
      platform = Api::Platform.create(name: "test-platform-2", uid: "12345678", version: "1.0")
      assert_equal "test-platform-2", platform.name
      assert_equal "12345678", platform.uid
    end
  end

  context "state machine" do
    setup do
      @active   = FactoryGirl.create(:platform, aasm_state: "active")
      @inactive = FactoryGirl.create(:platform, aasm_state: "inactive")
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
