ActiveAdmin.register Payola::Subscription, as: "Subscription" do
  menu label: "Subscriptions", parent: "Plans"

  filter :created_at
end
