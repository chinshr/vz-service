require 'test_helper'

class Payment::SubscriptionMailerTest < ActionMailer::TestCase
  def setup
    @subscription = FactoryGirl.create(:subscription)
  end

  context "#active" do
    should "send subscription active" do
      mail = Payment::SubscriptionMailer.active(@subscription.guid)
      assert_equal "Subscription active", mail.subject
      assert_equal @subscription.email, mail.to.first
      assert_equal "support@voyz.es", mail.from.first
    end

    should "deliver a subscription active" do
      assert_difference "ActionMailer::Base.deliveries.count", 1 do
        Payment::SubscriptionMailer.active(@subscription.guid).deliver_now
      end
    end
  end

  context "#plan_changed" do
    should "send subscription plan_changed" do
      mail = Payment::SubscriptionMailer.plan_changed(@subscription.guid)
      assert_equal "Subscription plan changed", mail.subject
      assert_equal @subscription.email, mail.to.first
      assert_equal "support@voyz.es", mail.from.first
    end

    should "deliver a subscription plan_changed" do
      assert_difference "ActionMailer::Base.deliveries.count", 1 do
        Payment::SubscriptionMailer.plan_changed(@subscription.guid).deliver_now
      end
    end
  end

  context "#canceled" do
    should "send subscription canceled" do
      mail = Payment::SubscriptionMailer.canceled(@subscription.guid)
      assert_equal "Subscription canceled", mail.subject
      assert_equal @subscription.email, mail.to.first
      assert_equal "support@voyz.es", mail.from.first
    end

    should "deliver a subscription canceled" do
      assert_difference "ActionMailer::Base.deliveries.count", 1 do
        Payment::SubscriptionMailer.canceled(@subscription.guid).deliver_now
      end
    end
  end
end
