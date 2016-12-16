ActiveAdmin.register Ingest do
  permit_params

  filter :created_at

  index do
    selectable_column
    column :id do |resource|
      link_to(resource.id, resource_path(resource), {title: resource.uid})
    end
    column :state do |resource|
      resource_state_status_tag(resource)
    end
    column :stage do |resource|
      span class: "status_tag" do
        resource.aasm_stage
      end
    end
    column :progress do |resource|
      resource_progress_tag(resource)
    end
    column :iteration
    column :busy
    column :terminate
    column :created_at
    column do |resource|
      links = ""
      links += link_to I18n.t('active_admin.view'), resource_path(resource), :class => "member_link view_link"
      (resource.aasm(:default).events.map(&:name) - [:process, :fail, :finish]).each do |event|
        links += link_to event.to_s.humanize, switch_admin_ingest_path(resource, params.merge(:event => event)),
          :class => "member_link view_link button", :confirm => "Really want to #{event.to_s.humanize.downcase}?"
      end
      links.html_safe
    end
  end

  show do
    attributes_table do
      row :id
      row :uid
      row :type
      row :progress do |resource|
        resource_progress_tag(resource)
      end
      row :state do |resource|
        resource_state_status_tag(resource)
      end
      row :stage do |resource|
        resource_status_tag(resource.stage)
      end

      row :iteration
      row :busy
      row :use_source_annotations

      row :terminate
      row :created_at
      row :updated_at
      row :started_at
      row :stopped_at
      row :reset_at
      row :removed_at
      row :finished_at
      row :restarted_at
      row :deleted_at

      row :upload
      row :document

      row :handle
      row :file_name
      row :file_type
      row :file_size
      row :source_url
      row :origin_url

      row :metadata
      row :messages

      panel "Workers" do
        table_for resource.workers do
          column :id do |resource|
            link_to resource.id, admin_ingest_worker_path(resource), {title: resource.uid}
          end
          column :worker_name do |resource|
            link_to resource.worker_name, admin_ingest_worker_path(resource)
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
        end
      end

    end
  end

  member_action :switch do
    resource = Ingest.find(params[:id])
    resource.send(:"#{params[:event]}!")
    params.delete(:controller)
    params.delete(:action)
    params.delete(:event)
    params.delete(:id)
    redirect_to admin_ingests_path(params)
  end

end
