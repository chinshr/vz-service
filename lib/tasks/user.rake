namespace :user do
  namespace :roles do
    desc "Give every user a default role"
    task :init => :environment do
      ::User.find_each do |user|
        if user.valid? && user.changes.include?(:roles_mask)
          user.update_column(:roles_mask, user.roles_mask)
        end
      end
    end
  end
end