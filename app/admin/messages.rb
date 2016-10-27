ActiveAdmin.register Message do
  filter :from
  filter :to
  filter :subject
  filter :text

  index do
    selectable_column
    column :id
    column :from
    column :to
    column :subject
    column :created_at
    actions
  end
end
