ActiveAdmin.register User do
  scope :all
  scope :confirmed
  permit_params :email, :city, :first_name, :last_name,
    :initials, :username

  controller do
    def find_resource
      scoped_collection.friendly.find(params[:id])
    end
  end

  index do
    column :id
    column :email
    column :confirmed_at
    column :time_zone
    column :sign_in_count
    column :failed_attempts
    column :created_at
    actions
  end
end
