ActiveAdmin.register Document do
  permit_params :title, :description, :privacy_mask, :locale
  
  scope :all
  scope :recent
  
  index do
    column :id
    column :title
    column(:privacy) do |resource|
      resource.privacy.map(&:to_s).join(", ")
    end
    column :locale
    column :created_at
    
    default_actions
  end
  
end
