Payola.configure do |config|
  config.secret_key = APP_CONFIG['STRIPE_API_KEY']
  config.publishable_key = APP_CONFIG['STRIPE_PUBLISHABLE_KEY']

  # config.background_worker = :active_job  # -> auto default

  config.support_email = "support@voyz.es"
  config.pdf_receipt = false

  # admin mails
  config.send_email_for :admin_receipt, :admin_dispute, :admin_refund, :admin_failure

  config.subscribe 'payola.sale.finished' do |sale|
    Payment::ReceiptMailer.receipt(sale.guid).deliver_later
  end

  config.subscribe 'payola.sale.refunded' do |sale|
    Payment::ReceiptMailer.refund(sale.guid).deliver_later
  end

  # Keep this subscription unless you want to disable refund handling
  config.subscribe 'charge.refunded' do |sale|
    if sale.is_a?(Stripe::Event)
      sale = Payola::Sale.find_by!(stripe_id: sale.data.object.id)
    end
    sale.refund! unless sale.refunded?
  end

  # payola.subscription.active
  config.subscribe 'payola.subscription.active' do |subscription|
    User.update_subscription_plan(subscription)
    Payment::SubscriptionMailer.active(subscription.guid).deliver_later
  end

  # payola.subscription.plan_changed
  config.subscribe 'payola.subscription.plan_changed' do |subscription|
    User.update_subscription_plan(subscription)
    Payment::SubscriptionMailer.plan_changed(subscription.guid).deliver_later
  end

  # payola.subscription.canceled
  config.subscribe 'payola.subscription.canceled' do |subscription|
    User.update_subscription_plan(subscription)
    Payment::SubscriptionMailer.canceled(subscription.guid).deliver_later
  end

end
