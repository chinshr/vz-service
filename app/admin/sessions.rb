ActiveAdmin.register Session do
  index do
    column :uid
    column :ip
    column :user_agent
    column :created_at
    column :updated_at
    # default_actions
    column do |resource|
      links = ""
      links += link_to I18n.t('active_admin.view'), resource_path(resource), :class => "member_link view_link"
      links.html_safe
    end
  end
end
