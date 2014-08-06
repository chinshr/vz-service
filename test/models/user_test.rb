require 'test_helper'

class UserTest < ActiveSupport::TestCase
  context "associations" do
    should have_many :documents
    should have_many :ingests
    should have_many :uploads
  end
  
  context "validations" do
    should "validate_presence_of :first_name, :last_name if confirmed?" do
      user = User.new(:confirmed_at => Time.now.utc)
      assert_equal true, user.confirmed?
      assert_equal false, user.valid?
      assert_equal ["can't be blank"], user.errors[:first_name]
      assert_equal ["can't be blank"], user.errors[:last_name]
    end
  end

  setup do
    # WebMock.allow_net_connect!
    stub_request(:get, "http://freegeoip.net/json/95.63.14.59").
      with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
      to_return(:status => 200, :body => "{\"ip\":\"95.63.14.59\",\"country_code\":\"ES\",\"country_name\":\"Spain\",\"region_code\":\"29\",\"region_name\":\"Madrid\",\"city\":\"Madrid\",\"zipcode\":\"28010\",\"latitude\":40.4306,\"longitude\":-3.6933,\"metro_code\":\"\",\"area_code\":\"\"}\n", :headers => {})
  end
  
  should "geocode and reverse geocode" do
    user = FactoryGirl.build(:user)
    assert_equal true, user.save
    assert_not_nil user.lat
    assert_not_nil user.lng
    assert_not_nil user.region_code
  end
end
