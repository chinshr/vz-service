ActiveAdmin.register Plan do
  permit_params :name, :key, :stripe_id, :amount, :interval, :features,
    :highlight, :display_order, :enabled, :visible, :create_stripe,
    :config

  filter :name
  filter :interval
  filter :amount

  index do
    selectable_column
    column :id do |resource|
      link_to(resource.id, resource_path(resource), {title: resource.uid})
    end
    column :name do |resource|
      link_to(resource.name, resource_path(resource))
    end
    column :key
    column :stripe_id
    column :interval
    column :amount
    column :highlight
    column :display_order
    column :enabled
    column :visible
    column :create_stripe
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :uid
      row :name
      row :key
      row :stripe_id
      row :interval
      row :amount
      row :features
      row :highlight
      row :display_order
      row :enabled
      row :visible
      row :create_stripe
      row :config do |resource|
        JSON.pretty_generate(resource.config.as_json)
      end
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.inputs "Plan Details" do
      f.input :name
      f.input :key
      f.input :stripe_id
      f.input :interval
      f.input :amount
      f.input :highlight
      f.input :display_order
      f.input :features, as: :text
      f.input :enabled
      f.input :visible
      f.input :create_stripe
      f.input :config, as: :text, input_html: {value: JSON.pretty_generate(f.object.config.as_json), class: 'ace-editor' }
    end
    f.actions
  end

end
