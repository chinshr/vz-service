ActiveAdmin.register User do
  actions :all, :except => [:new]

  scope :all
  scope :confirmed

  permit_params :email, :city, :first_name, :last_name,
    :initials, :username

  controller do
    def find_resource
      scoped_collection.friendly.find(params[:id])
    end
  end

  filter :email
  filter :confirmed_at
  filter :first_name
  filter :last_name
  filter :username
  filter :uid

  index do
    selectable_column
    column :id
    column :email
    column :confirmed_at
    column :time_zone
    column :sign_in_count
    column :failed_attempts
    column :created_at
    actions
  end

  show do |user|
    attributes_table do
      User.column_names.each do |column|
        row column
      end
      row :login_as do
        link_to "#{user.name}", login_as_admin_user_path(user.id), :target => '_blank', :class => "button"
      end
    end
  end

  # Allows admins to login as a user
  member_action :login_as, :method => :get do
    user = User.find(params[:id])
    sign_in(user, bypass: true)
    redirect_to web_dashboard_path
  end
end
