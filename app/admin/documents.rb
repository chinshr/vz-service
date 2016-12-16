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

end
