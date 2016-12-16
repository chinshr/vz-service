ActiveAdmin.register Ingest::Worker do
  menu label: "Workers", parent: "Ingests"

  actions :all, :except => [:new, :edit, :destroy]

  permit_params

  filter :created_at

  index do
    selectable_column
    column :id do |resource|
      link_to(resource.id, resource_path(resource), {title: resource.uid})
    end
    column :worker_name
    column :state do |resource|
      resource_state_status_tag(resource)
    end
    column :lock_count
    column :ingest_iteration
    column :server do |resource|
      if resource.server
        link_to(resource.server.instance_id, resource_path(resource.server))
      end
    end
    column :started_at
    column :stopped_at
    column :finished_at
    column do |resource|
      links = ""
      links += link_to I18n.t('active_admin.view'), resource_path(resource), :class => "member_link view_link"
      # (resource.aasm(:default).events.map(&:name) - []).each do |event|
      #   links += link_to event.to_s.humanize, switch_admin_ingest_worker_path(resource, params.merge(:event => event)),
      #     :class => "member_link view_link button", :confirm => "Really want to #{event.to_s.humanize.downcase}?"
      # end
      links.html_safe
    end
  end

end
