ActiveAdmin.register Document do
  permit_params :title, :description, :privacy_mask, :locale

  scope :all
  scope :recent

  controller do
    def find_resource
      scoped_collection.friendly.find(params[:id])
    end
  end

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
