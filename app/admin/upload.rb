ActiveAdmin.register Upload do
  permit_params 

  scope :all
  scope :started
  scope :stopped
  scope :reset
  scope :removed
  scope :finished
  
  index do
    column :id
    column :title do |resource|
      link_to resource.title, admin_document_path(resource)
    end
    column :s3_url
    column :locale
    column :created_at
    column :progress
    column(:state) do |resource|
      colors = {:created => :grey, :starting => :grey, :started => :ok, :restarting => :grey,
        :stopping => :error, :stopped => :error, :resetting => :warning, :reset => :warning, 
        :finished => :ok, :removing => :warning, :removed => :warning}
      status_tag(resource.ingest.state.to_s, colors[resource.ingest.state])
    end
    column do |resource|
      links = ""
      links += link_to I18n.t('active_admin.view'), resource_path(resource), :class => "member_link view_link"
      (resource.ingest.aasm_events_for_current_state - [:process, :fail, :finish]).each do |event|
        links += link_to event.to_s.humanize, switch_admin_upload_path(resource, :event => event), 
          :class => "member_link view_link button", :confirm => "Really want to #{event.to_s.humanize.downcase}?"
      end
      links.html_safe
    end
    
  end
  
  member_action :switch do
    resource = Upload.find(params[:id])
    ingest = resource.ingest
    ingest.send(:"#{params[:event]}!")
    redirect_to admin_uploads_path
  end
  
end
