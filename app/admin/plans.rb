ActiveAdmin.register Plan do
  permit_params :name, :amount, :interval, :features,
    :highlight, :display_order, :enabled, :visible

  filter :name
  filter :interval
  filter :amount

end
