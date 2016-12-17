ActiveAdmin.register Ingest::Worker do
  menu label: "Workers", parent: "Ingests"

  actions :all, :except => [:new, :edit, :destroy]

  permit_params

  filter :worker_name
  filter :aasm_state, label: "State"
  filter :lock_count
  filter :ingest_iteration
  filter :started_at
  filter :stopped_at
  filter :finished_at

  scope :all
  scope :active

  index do
    selectable_column
    column :id do |resource|
      link_to(resource.id, resource_path(resource), {title: resource.uid})
    end
    column :worker_name do |resource|
      link_to(resource.worker_name, resource_path(resource))
    end
    column :state do |resource|
      resource_state_status_tag(resource)
    end
    column :lock_count
    column :ingest_iteration
    column :server do |resource|
      if resource.server
        link_to(resource.server.instance_id, admin_ingest_server_path(resource.server))
      end
    end
    column :started_at
    column :stopped_at
    column :finished_at
    column :actions do |resource|
      links = ""
      links += link_to I18n.t('active_admin.view'), resource_path(resource), :class => "member_link view_link"
      resource.aasm(:default).events(permitted: true).map(&:name).each do |event|
        links += link_to event.to_s.humanize, switch_admin_ingest_path(resource, params.merge(:event => event)),
          :class => "member_link view_link button", :confirm => "Really want to #{event.to_s.humanize.downcase}?"
      end
      links.html_safe
    end
  end

  member_action :switch do
    resource = Ingest::Worker.find(params[:id])
    resource.send(:"#{params[:event]}!")
    params.delete(:controller)
    params.delete(:action)
    params.delete(:event)
    params.delete(:id)
    redirect_to admin_ingest_worers_path(params)
  end

end
