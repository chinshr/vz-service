ActiveAdmin.register Plan do
  permit_params :name, :price, :interval, :features,
    :highlight, :display_order
end
