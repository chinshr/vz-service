class Web::Account::BillingsController < Web::Account::ApplicationController

  # [GET] /account/billing(.:format)
  def show
    @plans = Plan.with_stripe.visible.enabled.order(display_order: :asc)
    @plan  = @subscription.plan if @subscription
    @sales = Payola::Sale.where(email: current_user.email).order(created_at: :desc)
  end

end
