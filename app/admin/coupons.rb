ActiveAdmin.register Payola::Coupon, as: "Coupon" do
  menu label: "Coupons", parent: "Plans"

  permit_params :code, :percent_off, :active

  filter :code
  filter :active
  filter :percent_off
  filter :created_at
end
