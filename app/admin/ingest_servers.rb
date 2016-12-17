ActiveAdmin.register Ingest::Server do
  menu label: "Servers", parent: "Ingests"

  permit_params

  actions :all, :except => [:new, :edit, :destroy]

  filter :created_at
  filter :id
  filter :uid
  filter :instance_id
  filter :version
  filter :aasm_state, label: "State"
  filter :private_ip_address, label: "Private IP"
  filter :public_ip_address, label: "Public IP"

  scope :all, default: true
  scope :pending
  scope :enabled
  scope :disabled
  scope :available
  scope :without_workers
  scope :without_busy_workers

  index do
    selectable_column
    column :id do |resource|
      link_to(resource.id, resource_path(resource), {title: resource.uid})
    end
    column :type do |resource|
      link_to(resource.type, resource_path(resource))
    end
    column :name
    column :state do |resource|
      resource_state_status_tag(resource)
    end
    column :instance_id
    column :instance_type
    column :max_workers
    column :enabled_at
    column :disabled_at
    column :stopped_at

    column :actions do |resource|
      links = ""
      links += link_to I18n.t('active_admin.view'), resource_path(resource), :class => "member_link view_link"
      (resource.aasm(:default).events(permitted: true).map(&:name) - []).each do |event|
        links += link_to event.to_s.humanize, switch_admin_ingest_worker_path(resource, params.merge(:event => event)),
          :class => "member_link view_link button", :confirm => "Really want to #{event.to_s.humanize.downcase}?"
      end
      links.html_safe
    end
  end
end
