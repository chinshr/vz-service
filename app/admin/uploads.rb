ActiveAdmin.register Upload do
  permit_params 

  scope :all
  scope :started
  scope :stopped
  scope :reset
  scope :removed
  scope :finished
  
  batch_action :delete do |ids|
    Upload.removed.find(ids).each do |upload|
      upload.destroy
    end
    redirect_to collection_path, alert: "The uploads have been deleted."
  end
    
  index do
    selectable_column
    column :id
    column :title do |resource|
      link_to resource.title, admin_document_path(resource)
    end
    column :s3_url
    column :locale
    column :created_at
    column :progress do |resource|
      %(<div class="progressbar"><div style="width:#{resource.ingest.progress}%"></div></div>).html_safe
    end
    column :iteration do |resource|
      resource.ingest.iteration
    end
    column(:state) do |resource|
      colors = {:created => :grey, :starting => :grey, :started => :ok, :restarting => :grey,
        :stopping => :grey, :stopped => :error, :resetting => :warning, :reset => :warning, 
        :finished => :ok, :removing => :warning, :removed => :warning}
      status_tag(resource.ingest.state.to_s, colors[resource.ingest.state])
    end
    column do |resource|
      links = ""
      links += link_to I18n.t('active_admin.view'), resource_path(resource), :class => "member_link view_link"
      if resource.ingest.state == :removed
        links += link_to "Delete", resource_path(resource), 
          :method => :delete, :class => "member_link delete_link", :confirm => "Are you really really really sure?"
      end
      (resource.ingest.aasm.events(resource.ingest.aasm.current_state) - [:process, :fail, :finish]).each do |event|
        links += link_to event.to_s.humanize, switch_admin_upload_path(resource, params.merge(:event => event)), 
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
