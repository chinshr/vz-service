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

  config.subscribe 'payola.subscription.active' do |subscription|
    if subscription.owner && !subscription.owner.confirmed_at
      subscription.owner.send_confirmation_instructions if subscription.owner.send(:send_confirmation_notification?)
      subscription.owner.send_admin_notification if subscription.owner.send(:send_admin_notification?)
    end

    User.update_subscription_plan(subscription)
    Payment::SubscriptionMailer.active(subscription.guid).deliver_later
  end

  config.subscribe 'payola.subscription.plan_changed' do |subscription|
    User.update_subscription_plan(subscription)
    Payment::SubscriptionMailer.plan_changed(subscription.guid).deliver_later
  end

  config.subscribe 'payola.subscription.canceled' do |subscription|
    User.update_subscription_plan(subscription, cancel: true)
    Payment::SubscriptionMailer.canceled(subscription.guid).deliver_later
  end

  config.subscribe 'payola.subscription.failed' do |subscription|
    # delete user who's subscription has just failed to process
    if subscription.owner && !subscription.owner.confirmed_at
      subscription.update_columns(owner_id: nil, owner_type: nil)
      subscription.owner.destroy_fully!
    end
  end
end
