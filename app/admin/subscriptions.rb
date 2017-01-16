ActiveAdmin.register Payola::Subscription, as: "Subscription" do
  menu label: "Subscriptions", parent: "Plans"

  actions :all, :except => [:new, :edit, :destroy]

  filter :email
  filter :guid
  filter :state
  filter :stripe_status
  filter :stripe_token
  filter :created_at

  scope :all
  scope :pending
  scope :processing
  scope :active
  scope :canceled
  scope :errored

  index do
    column :id do |resource|
      link_to(resource.id, "subscriptions/#{resource.id}")
    end
    column :email
    column :plan
    column :guid
    column :amount do |resource|
      number_to_currency(resource.amount / 100.0, {unit: "$"})
    end
    column :state
    column :stripe_status
    column :card_type
    column :card_last4
    column "Canceled", :cancel_at_period_end
    column :created_at

    # actions
    column do |resource|
      links = ""
      links += link_to I18n.t('active_admin.view'), "subscriptions/#{resource.id}", :class => "member_link view_link"
      links.html_safe
    end
  end

end
