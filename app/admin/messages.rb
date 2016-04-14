ActiveAdmin.register Message do
  filter :from
  filter :to
  filter :subject
  filter :text

  index do
    column :id
    column :from
    column :to
    column :subject
    column :created_at
    default_actions
  end
end
