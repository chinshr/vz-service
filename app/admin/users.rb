ActiveAdmin.register User do
  actions :all, :except => [:new, :destroy]

  scope :all
  scope :approved
  scope :unapproved
  scope :confirmed
  scope :unconfirmed

  permit_params :plan_id, :username, :first_name, :last_name, :initials, :email,
    :lat, :lng, :time_zone, :address, :country_code, :city, :postal_code,
    :region_code, :region_name, :avatar_url, :css_hex_color, :properties,
    :approved

  controller do
    def find_resource
      scoped_collection.friendly.find(params[:id])
    end
  end

  filter :email
  filter :approved
  filter :confirmed_at
  filter :first_name
  filter :last_name
  filter :username
  filter :uid

  index do
    selectable_column
    column :id
    column :email
    column :time_zone
    column :sign_in_count
    column :failed_attempts
    column :approved
    column :created_at
    column :confirmed_at
    column do |resource|
      links = ""
      links += link_to I18n.t('active_admin.view'), resource_path(resource), :class => "member_link view_link"
      links += link_to I18n.t('active_admin.edit'), edit_resource_path(resource), :class => "member_link edit_link"
      if resource.approved?
        links += link_to "Block", switch_admin_user_path(resource.id, switch_params.merge(:event => "unapprove")),
          :class => "member_link view_link button", :confirm => "Really want to block?"
      else
        links += link_to "Accept", switch_admin_user_path(resource.id, switch_params.merge(:event => "approve")),
          :class => "member_link view_link button", :confirm => "Really want to accept?"
      end
      links.html_safe
    end
  end

  show do |user|
    attributes_table do
      User.column_names.reject {|n| ['properties'].include?(n) }.each do |column|
        row column
      end
      row :properties do |resource|
        JSON.pretty_generate(resource.properties.as_json)
      end
      row :login_as do
        link_to "#{user.name}", login_as_admin_user_path(user.id), :target => '_blank', :class => "button"
      end
    end
  end

  form do |f|
    f.inputs "User Details" do
      f.input :plan
      f.input :username
      f.input :first_name
      f.input :last_name
      f.input :initials
      f.input :email
      f.input :approved
      f.input :lat
      f.input :lng
      # f.input :time_zone
      f.input :address
      f.input :country_code
      f.input :city
      f.input :postal_code
      f.input :region_code
      f.input :region_name
      f.input :avatar_url
      f.input :css_hex_color

      f.input :properties, as: :text, input_html: {value: JSON.pretty_generate(f.object.properties.as_json), class: 'ace-editor' }
    end
    f.actions
  end

  # Allows admins to login as a user
  member_action :login_as, :method => :get do
    user = User.find(params[:id])
    sign_in(user, bypass: true)
    redirect_to web_dashboard_path
  end

  member_action :switch do
    resource = User.find(params[:id])
    if params[:event] == "approve"
      resource.update_attribute(:approved, true)
    elsif params[:event] == "unapprove"
      resource.update_attribute(:approved, false)
    end
    redirect_to admin_users_path(switch_params)
  end
end
