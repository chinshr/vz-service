require 'test_helper'

class UserTest < ActiveSupport::TestCase
  setup do
    # WebMock.allow_net_connect!
    stub_request(:get, "http://freegeoip.net/json/95.63.14.59").
      with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
      to_return(:status => 200, :body => "{\"ip\":\"95.63.14.59\",\"country_code\":\"ES\",\"country_name\":\"Spain\",\"region_code\":\"29\",\"region_name\":\"Madrid\",\"city\":\"Madrid\",\"zipcode\":\"28010\",\"latitude\":40.4306,\"longitude\":-3.6933,\"metro_code\":\"\",\"area_code\":\"\"}\n", :headers => {})
  end

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

  should "geocode and reverse geocode" do
    user = FactoryGirl.build(:user)
    assert_equal true, user.save
    assert_not_nil user.lat
    assert_not_nil user.lng
    assert_not_nil user.region_code
  end

  should "have name" do
    user = FactoryGirl.create(:user, first_name: "Jürgen", last_name: "Feßlmeier")
    assert_equal "Jürgen Feßlmeier", user.name

    user.attributes = {first_name: "Jürgen", last_name: nil}
    assert_equal "Jürgen", user.name

    user.attributes = {first_name: nil, last_name: nil}
    assert_equal "", user.name
  end

  should "have initials" do
    user = User.new(first_name: "jürgen", last_name: "feßlmeier")
    assert_equal "JF", user.initials

    user = User.new(first_name: "jürgen")
    assert_equal "J", user.initials

    user = User.new
    assert_equal "", user.initials
  end

  should "have css_rgb" do
    user = FactoryGirl.create(:user, id: 6666)
    assert_equal "rgb(118, 242, 7)", user.css_rgb_color
  end

  context "user registration" do
    should "not be valid without previous registration" do
      user = FactoryGirl.build(:user, first_name: "Jürgen", last_name: "Feßlmeier", email: "juergen@example.com")
      user.force_registration_validation = true
      assert_equal false, user.valid?, "should not be valid"
    end

    should "skip registration" do
      user = FactoryGirl.build(:user, first_name: "Jürgen", last_name: "Feßlmeier", email: "juergen@example.com")
      user.skip_registration_validation = true
      assert_equal true, user.valid?, "should be valid"
    end

    should "not be valid with pending registration" do
      registration = FactoryGirl.build(:registration, email: "juergen@example.com")
      user = FactoryGirl.build(:user, first_name: "J", last_name: "F", email: "juergen@example.com")
      user.force_registration_validation = true
      assert_equal false, user.valid?, "should not be valid"
    end

    should "not be valid with declined registration" do
      registration = FactoryGirl.build(:registration, email: "juergen@example.com")
      assert_equal true, registration.decline!
      user = FactoryGirl.build(:user, first_name: "J", last_name: "F", email: "juergen@example.com")
      user.force_registration_validation = true
      assert_equal false, user.valid?, "should not be valid"
    end

    should "be valid with accepted registration" do
      registration = FactoryGirl.build(:registration, email: "juergen@example.com")
      assert_equal true, registration.accept!
      user = FactoryGirl.build(:user, first_name: "J", last_name: "F", email: "juergen@example.com")
      user.force_registration_validation = true
      assert_equal true, user.valid?, "should be valid"
    end
  end

  context "roles" do
    should "get and set roles" do
      user = User.new(:confirmed_at => Time.now.utc)
      assert_equal [], user.roles
      user.valid?
      assert_equal [:user], user.roles
      user.roles = [:backend]
      assert_equal [:backend], user.roles
    end

    should "#user_role?" do
      assert_equal true, FactoryGirl.create(:user).user_role?
      assert_equal true, FactoryGirl.create(:backend_user).user_role?
      assert_equal true, FactoryGirl.create(:admin_user).user_role?
      assert_equal true, FactoryGirl.create(:developer_user).user_role?
    end

    should "#backend_role?" do
      assert_equal true, FactoryGirl.create(:backend_user).backend_role?
      assert_equal true, FactoryGirl.create(:admin_user).backend_role?
      assert_equal false, FactoryGirl.create(:user).backend_role?
    end
  end

  should "be #owner_of?" do
    document1 = FactoryGirl.create(:document)
    user1     = document1.user
    document2 = FactoryGirl.create(:document)
    assert_equal true, user1.owner_of?(document1)
    assert_equal false, user1.owner_of?(document2)
  end
end
