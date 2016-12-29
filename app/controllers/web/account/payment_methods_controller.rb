class Web::Account::PaymentMethodsController < Web::Account::ApplicationController
  before_filter :find_plan, only: [:new]
  before_filter :find_subscription, only: [:update]

  # [GET] /account/billing/payment_method/new(.:format)
  def new
    @subscription = Payola::Subscription.new(plan: @plan)
  end

  # [GET] /account/billing/payment_method(.:format)
  def show
    @subscription, @plan = current_subscription, current_subscription.plan
  end

  # [PUT] /account/billing/payment_method(.:format)
  def update
    update_card
  end

  protected

  def update_card
    Payola::UpdateCard.call(@subscription, params[:stripeToken])
    confirm_subscription_status_with_message(t('payola.subscriptions.card_updated'))
  end

  def use_account_split_view?
    false
  end
  helper_method :use_account_split_view?
end
