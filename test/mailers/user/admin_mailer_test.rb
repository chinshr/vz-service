require 'test_helper'

class User::AdminMailerTest < ActionMailer::TestCase
  context "#new_user_signup" do
    setup do
      @user = FactoryGirl.create(:user, :approved)
    end

    should "send" do
      mail = User::AdminMailer.new_user_signup(@user)
      assert_equal "New user signup", mail.subject
    end
  end

  context "#new_user_waiting_for_approval" do
    setup do
      @user = FactoryGirl.create(:user, :unapproved)
    end

    should "send" do
      mail = User::AdminMailer.new_user_waiting_for_approval(@user)
      assert_equal "New user waiting for approval", mail.subject
    end
  end
end
