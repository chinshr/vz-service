module PaymentBehavior
  extend ActiveSupport::Concern

  protected

  def create_subscription(owner = current_user)
    @subscription = Payola::CreateSubscription.call(create_subscription_params, owner)
    render_payola_status(@subscription)
  end

  def change_subscription_plan
    Payola::ChangeSubscriptionPlan.call(@subscription, @plan, 1, @coupon)
    confirm_subscription_with_message(t('payola.subscriptions.plan_updated'))
  end

  def cancel_subscription(redirect_url = web_account_billing_path, options = {})
    options = {at_period_end: true}.merge(options)
    Payola::CancelSubscription.call(@subscription, options)
    redirect_to redirect_url, notice: t('payola.subscriptions.plan_canceled') if redirect_url
  end

  def confirm_subscription_with_message(message)
    if @subscription.errors.empty?
      redirect_to web_account_billing_path, notice: message
    else
      redirect_to web_account_billing_path, alert: @subscription.errors.full_messages.to_sentence
    end
  end

  def confirm_subscription_status_with_message(message, redirect_url = web_account_billing_path)
    errors  = ([@subscription.error.presence] + @subscription.errors.full_messages).compact.to_sentence
    as_json = {
      guid:   @subscription.guid,
      status: @subscription.state,
      error:  errors.presence
    }

    # Note: force mime format to json if request type empty
    request.format = Mime::Type.new(:json) unless request.format.to_sym

    respond_to do |format|
      format.html {
        if @subscription.errors.empty?
          redirect_to redirect_url, notice: message
        else
          redirect_to redirect_url, alert: errors
        end
      }
      format.json {
        if @subscription.errors.empty?
          render json: as_json, status: 200, notice: message
        else
          render json: as_json, status: 400, alert: errors
        end
      }
    end
  end

  def find_plan
    plan_id = params[:plan_id] || params[:plan] || params[:user].try(:[], :plan_id)
    @plan = if plan_id
      plan_class.enabled.where(plan_class.arel_table[:id].eq(plan_id).or(plan_class.arel_table[:uid].eq(plan_id)).or(plan_class.arel_table[:stripe_id].eq(plan_id))).first!
    end
  end

  def find_subscription
    @subscription = if params[:guid]
      Payola::Subscription.find_by!(guid: params[:guid])
    else
      Payola::Subscription.find_by(owner: current_user)
    end
  end

  def find_coupon
    @coupon = cookies[:cc] || params[:cc] || params[:coupon_code] || params[:coupon]
  end

  def plan_class
    @plan_class ||= Payola.subscribables[params[:plan_class] || "plan"]
  end

  def find_plan_and_coupon
    find_plan
    find_coupon
  end

  def create_subscription_params
    params.permit!.merge({
      plan: @plan,
      coupon: @coupon,
      quantity: @quantity,
      affiliate: @affiliate
    })
  end

end
