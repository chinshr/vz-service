require 'test_helper'

class UserTest < ActiveSupport::TestCase
  setup do
    # WebMock.allow_net_connect!
    stub_request(:get, "http://freegeoip.net/json/95.63.14.59").
      with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
      to_return(:status => 200, :body => "{\"ip\":\"95.63.14.59\",\"country_code\":\"ES\",\"country_name\":\"Spain\",\"region_code\":\"29\",\"region_name\":\"Madrid\",\"city\":\"Madrid\",\"zipcode\":\"28010\",\"latitude\":40.4306,\"longitude\":-3.6933,\"metro_code\":\"\",\"area_code\":\"\"}\n", :headers => {})
  end

  context "associations" do
    should have_many(:documents).dependent(:nullify)
    should have_many(:uploads).dependent(:nullify)
    should have_many(:ingests).through(:uploads)
    should belong_to(:plan)
  end

  context "validations" do
    subject { User.new(:confirmed_at => Time.zone.now) }

    should "validate_presence_of :first_name, :last_name, :username if confirmed?" do
      user = User.new(:confirmed_at => Time.zone.now)
      assert_equal true, user.confirmed?
      assert_equal false, user.valid?
      assert_equal true, user.errors[:name].include?("can't be blank")
      assert_equal true, user.errors[:username].include?("invalid format")
      assert_equal true, user.errors[:username].include?("is too short (minimum is 2 characters)")
    end

    should "not downcase empty email address" do
      user = User.new(:email => nil)
      assert_equal false, user.valid?
      assert_nil user.email
    end

    should "downcase email address" do
      user = User.new(:email => "TeST@ExAMplE.cOM")
      assert_equal true, user.valid?
      assert_equal "test@example.com", user.email
    end

    should validate_presence_of :username
    should validate_length_of(:username).is_at_least(2).is_at_most(40)
    should validate_presence_of :name
    should validate_length_of(:name).is_at_least(1).is_at_most(125)
    should validate_length_of(:description).is_at_most(240)
  end

  should "geocode and reverse geocode" do
    user = FactoryGirl.build(:user)
    assert_equal true, user.save
    assert_not_nil user.lat
    assert_not_nil user.lng
    assert_not_nil user.region_code
  end

  context "#name" do
    should "from name" do
      user = FactoryGirl.build(:user, name: "Joe Smith", first_name: nil, last_name: nil)
      assert_equal "Joe Smith", user.name
    end

    should "from first_name + last_name" do
      user = FactoryGirl.build(:user, first_name: "Jürgen", last_name: "Feßlmeier")
      assert_equal "Jürgen Feßlmeier", user.name

      user.attributes = {first_name: "Jürgen", last_name: nil}
      assert_equal "Jürgen", user.name

      user.attributes = {first_name: nil, last_name: nil}
      assert_nil user.name
    end
  end

  should "have #name_and_username" do
    user = FactoryGirl.create(:user, first_name: "Jürgen", last_name: "Feßlmeier", username: "jf")
    assert_equal "Jürgen Feßlmeier (@jf)", user.name_and_username

    user.attributes = {first_name: "Jürgen", last_name: nil}
    assert_equal "Jürgen (@jf)", user.name_and_username

    user.attributes = {first_name: nil, last_name: nil}
    assert_equal "@jf", user.name_and_username
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

  should "have pubsub_channel" do
    user = FactoryGirl.create(:user)
    assert_not_nil user.pubsub_channel
  end

  context "roles" do
    should "get and set roles" do
      user = User.new(:confirmed_at => Time.zone.now)
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

  context "slug" do
    should "generate valid slug with username" do
      user = FactoryGirl.create(:user, username: "hellotest")
      assert_equal "hellotest", user.slug
      assert_equal "hellotest", user.friendly_id
    end

    should "not generate duplicate slug" do
      FactoryGirl.create(:user, username: "hellotest")
      assert_raises ActiveRecord::RecordInvalid do
        FactoryGirl.create(:user, username: "hellotest")
      end
    end

    should "change slug when changing username" do
      user = FactoryGirl.create(:user, username: "hellotest")
      assert_equal "hellotest", user.slug
      assert_equal "hellotest", user.friendly_id
      user.update_attributes({username: "hellokitty"})
      assert_equal "hellokitty", user.friendly_id
      assert_equal "hellokitty", user.slug
    end

    should "not change to historic slug name" do
      u1 = FactoryGirl.create(:user, username: "chinshr")
      assert_equal "chinshr", u1.friendly_id
      u1.update_attributes({username: "juergen"})
      assert_equal "juergen", u1.friendly_id
      # assert_raises ActiveRecord::RecordInvalid do
      #   u2 = FactoryGirl.create(:user, username: "chinshr")
      # end
    end
  end

  context "scopes" do
    setup do
      @backend   = FactoryGirl.create(:user, :unconfirmed, :unapproved, roles: :backend)
      @user      = FactoryGirl.create(:user, :confirmed, :approved, roles: :user)
      @developer = FactoryGirl.create(:user, :unconfirmed, :approved, roles: :developer)
    end

    should "#any_of_roles" do
      assert_equal [@backend].to_set, User.any_of_roles(:backend).to_set
      assert_equal [@user].to_set, User.any_of_roles(:user).to_set
      assert_equal [@developer].to_set, User.any_of_roles(:developer).to_set
    end

    should "#confirmed" do
      assert_equal [@user].to_set, User.confirmed.to_set
    end

    should "#unconfirmed" do
      assert_equal [@backend, @developer].to_set, User.unconfirmed.to_set
    end

    should "#approved" do
      assert_equal [@user, @developer].to_set, User.approved.to_set
    end

    should "#unapproved" do
      assert_equal [@backend].to_set, User.unapproved.to_set
    end
  end

  should "#update_subscription_plan" do
    user = FactoryGirl.create(:user)
    subscription = FactoryGirl.create(:subscription, owner: user)
    assert_nil user.plan
    User.update_subscription_plan(subscription)
    assert_equal subscription.plan, user.plan
  end

  context "#properties" do
    setup do
      @user1 = FactoryGirl.create(:user)
      @user2 = FactoryGirl.create(:user, :with_personal_plan)
    end

    should "get" do
      assert_not_nil @user1.properties
    end

    should "get properties.config" do
      assert_not_nil @user1.properties.config
    end

    should "config.transcription.engine nil" do
      assert_nil @user1.properties.config.transcription.engine
    end

    should "config.transcription.engine inherited from plan" do
      assert_equal "test_engine", @user2.properties.config.transcription.engine
    end
  end
end
