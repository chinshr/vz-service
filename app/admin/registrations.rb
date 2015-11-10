ActiveAdmin.register Registration do
  scope :all
  scope :recent
  scope :accepted
  scope :declined

  index do
    column :email
    column :name
    column :locale
    column :ip_address
    column :created_at
    column(:state) do |resource|
      colors = {:pending => :grey, :accepted => :ok, :declined => :error}
      status_tag(resource.aasm_state.to_s, colors[resource.aasm_state.to_sym])
    end

    # default_actions
    column do |resource|
      links = link_to I18n.t('active_admin.view'), resource_path(resource), :class => "member_link view_link"
      links += link_to I18n.t('active_admin.edit'), edit_resource_path(resource), :class => "member_link edit_link"
      links += link_to I18n.t('active_admin.delete'), resource_path(resource), 
        :method => :delete, :class => "member_link delete_link", :confirm => "Are you really really really sure?"
      (resource.events - []).each do |event|
        links += link_to event.to_s.humanize, switch_admin_registration_path(resource, params.merge(:event => event)), 
          :class => "member_link view_link button", :confirm => "Really want to #{event.to_s.humanize.downcase}?"
      end
      links
    end
  end

  member_action :switch do
    resource = Registration.find(params[:id])
    resource.send(:"#{params[:event]}!")
    redirect_to admin_registrations_path
  end
end
