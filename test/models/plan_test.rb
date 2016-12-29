require 'test_helper'

class PlanTest < ActiveSupport::TestCase

  setup do
    Payola.create_stripe_plans = false
  end

  context "associations" do
    should have_many :users
  end

  context "validations" do
    subject { FactoryGirl.create(:plan, :enabled) }

    should validate_presence_of :stripe_id
  end

  context "scopes" do
    should "#enabled" do
      enabled = FactoryGirl.create(:plan, :enabled)
      assert_equal enabled, Plan.enabled.first
    end

    should "#disabled" do
      disabled = FactoryGirl.create(:plan, :disabled)
      assert_equal disabled, Plan.disabled.first
    end

    should "#visible" do
      visible = FactoryGirl.create(:plan, :visible)
      assert_equal visible, Plan.visible.first
    end

    should "#hidden" do
      hidden = FactoryGirl.create(:plan, :hidden)
      assert_equal hidden, Plan.hidden.first
    end

    should "#with_stripe" do
      with_stripe = FactoryGirl.create(:plan, :with_stripe)
      assert_equal with_stripe, Plan.with_stripe.first
    end

    should "#without_stripe" do
      without_stripe = FactoryGirl.create(:plan, :without_stripe)
      assert_equal without_stripe, Plan.without_stripe.first
    end
  end

  should "initialize" do
    assert_difference "Plan.count" do
      plan = FactoryGirl.create(:plan, :enabled)
    end
  end

  should "create stripe plan" do
    Payola.create_stripe_plans = true
    Payola::CreatePlan.expects(:call).once
    stripe_plan = FactoryGirl.create(:plan, :with_stripe)
  end

  should "not create stripe plan" do
    Payola.create_stripe_plans = true
    Payola::CreatePlan.expects(:call).never
    stripe_plan = FactoryGirl.create(:plan, :without_stripe)
  end
end
