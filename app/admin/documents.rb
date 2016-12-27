ActiveAdmin.register Document do
  permit_params :title, :description, :privacy_mask, :locale

  actions :all, :except => [:new, :edit, :destroy]

  scope("All") {|scope| scope.is_root }
  scope("Documents", default: true) {|scope| scope.is_root(true) }
  scope("Chunks") {|scope| scope.is_root(false) }
  scope("Recent Documents") {|scope| scope.is_root(true).recent(1000) }

  controller do
    def find_resource
      scoped_collection.friendly.find(params[:id])
    end
  end

  filter :title
  filter :description
  filter :published_at

  index do
    selectable_column
    column :id
    column :title do |resource|
      if resource.respond_to? :title
        link_to resource.title, web_document_path(resource.slug_id)
      end
    end
    column(:privacy) do |resource|
      resource.privacy.map(&:to_s).join(", ")
    end
    column :locale
    column :created_at

    actions
  end

  show do
    attributes_table do
      row :id
      row :uid
      row :title
      row :slug
      row :description
      row :privacy do |resource|
        resource_status_tag(resource.privacy.first)
      end
      row :locale
      row :html
      row :user
      row :rich_text
      row :text
      row :offset
      row :start_time
      row :end_time
      row :score
      row :type
      row :processing_status
      row :response do |resource|
        resource.response.to_json
      end
      row :ingest_iteration
      row :turkee_task
      row :slug
      row :state do |resource|
        resource_status_tag(resource.aasm_state)
      end
      row :accessibility_mask
      row :accessibility do |resource|
        resource_status_tag(resource.accessibility.first)
      end
      row :processed_stages_mask
      row :processed_stages do |resource|
        resource.processed_stages.map(&:to_s).join(", ")
      end

      row :created_at
      row :updated_at
      row :published_at
      row :removed_at
      row :deleted_at
    end
  end
end
