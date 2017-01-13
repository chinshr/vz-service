ActiveAdmin.register Payola::Affiliate, as: "Affiliate" do
  menu label: "Affiliates", parent: "Plans"

  permit_params :code, :email, :percent

  filter :code
  filter :email
  filter :percent
  filter :created_at
end
