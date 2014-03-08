require 'test_helper'

class UserTest < ActiveSupport::TestCase
=begin
  context "validations" do
    should "validate_presence_of :first_name, :last_name if confirmed?" do
      user = User.new(:confirmed_at => Time.now.utc)
      assert_equal true, user.confirmed?
      assert_equal false, user.valid?
      assert_equal ["can't be blank"], user.errors[:first_name]
      assert_equal ["can't be blank"], user.errors[:last_name]
    end
  end
=end
  
  should "geocode and reverse geocode" do
    user = FactoryGirl.build(:user)
    assert_equal true, user.save
    assert_not_nil user.lat
    assert_not_nil user.lng
    assert_not_nil user.region_code
  end
end
