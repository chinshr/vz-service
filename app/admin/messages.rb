ActiveAdmin.register Message do
  index do
    column :id
    column :from
    column :to
    column :subject
    column :created_at
    default_actions
  end
end
