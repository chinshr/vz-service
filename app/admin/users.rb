ActiveAdmin.register User do
  scope :all
  scope :confirmed
  
  index do
    column :id
    column :email
    column :confirmed_at
    column :time_zone
    column :sign_in_count
    column :failed_attempts
    column :created_at
    default_actions
  end
end
