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
    column :guid
    column :amount
    column :product_type
    column :state
    column :stripe_token
    column :card_type
    column :card_last4

    actions
  end
end
