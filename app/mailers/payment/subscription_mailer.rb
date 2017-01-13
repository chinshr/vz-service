class Payment::SubscriptionMailer < ApplicationMailer
  add_template_helper Web::ApplicationHelper
  helper Payola::PriceHelper

  def active(subscription_guid)
    ActiveRecord::Base.connection_pool.with_connection do
      @subscription = Payola::Subscription.find_by(guid: subscription_guid)
      @plan = @subscription.plan
      mail(mail_params({subject: "Subscription active"}))
    end
  end

  def plan_changed(subscription_guid)
    ActiveRecord::Base.connection_pool.with_connection do
      @subscription = Payola::Subscription.find_by(guid: subscription_guid)
      @plan = @subscription.plan
      mail(mail_params({subject: "Subscription plan changed"}))
    end
  end

  def canceled(subscription_guid)
    ActiveRecord::Base.connection_pool.with_connection do
      @subscription = Payola::Subscription.find_by(guid: subscription_guid)
      @plan = @subscription.plan
      mail(mail_params({subject: "Subscription canceled"}))
    end
  end

  protected

  def mail_params(params = {})
    @mail_params = {
      to: @subscription.email,
      from: Payola.support_email,
      subject: "Subscription"
    }.merge(params)
  end
end
