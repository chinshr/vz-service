ActiveAdmin.register Payola::Sale, as: "Sale" do
  menu label: "Sales", parent: "Plans"

  actions :all, :except => [:new, :edit, :destroy]

  filter :email
  filter :guid
  filter :state
  filter :card_last4
  filter :card_type
  filter :created_at

  scope :all
  scope :pending
  scope :processing
  scope :finished
  scope :errored
  scope :refunded

  index do
    column :id do |resource|
      link_to(resource.id, resource_path(resource))
    end
    column :email
    column "Plan", :owner do |resource|
      link_to(resource.owner.name, "plans/#{resource.owner.id}")
    end
    column :guid
    column :amount do |resource|
      number_to_currency(resource.amount / 100.0, {unit: "$"})
    end
    column :product_type
    column :state
    column :stripe_token
    column :card_type
    column :card_last4
    column :created_at

    actions
  end
end
