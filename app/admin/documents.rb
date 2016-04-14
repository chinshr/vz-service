ActiveAdmin.register Document do
  permit_params :title, :description, :privacy_mask, :locale

  scope("All", default: true) {|scope| scope.is_root }
  scope("Chunks") {|scope| scope.is_root(false) }
  scope("Recent") {|scope| scope.is_root.recent(1000) }

  controller do
    def find_resource
      scoped_collection.friendly.find(params[:id])
    end
  end

  filter :title
  filter :description
  filter :published_at

  index do
    column :id
    column :title
    column(:privacy) do |resource|
      resource.privacy.map(&:to_s).join(", ")
    end
    column :locale
    column :created_at

    actions
  end

end
