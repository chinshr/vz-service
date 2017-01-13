class Web::Account::SubscriptionsController < Web::Account::ApplicationController
  before_filter :find_plan_and_coupon, only: [:create, :update]
  before_filter :find_subscription, only: [:update, :destroy]

  # [POST] /account/billing/subscription(.:format)
  def create
    create_subscription
  end

  # [PUT] /account/billing/subscription(.:format)
  def update
    change_subscription_plan
  end

  # [DELETE] /account/billing/subscription(.:format)
  def destroy
    cancel_subscription
  end
end
