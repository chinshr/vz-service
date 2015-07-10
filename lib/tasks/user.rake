namespace :user do
  namespace :roles do
    desc "Set role 'user' as default for all users"
    task :set_default => :environment do
      ::User.find_each do |user|
        if user.valid? && user.changes.include?(:roles_mask)
          user.update_column(:roles_mask, user.roles_mask)
        end
      end
    end
  end

  namespace :username do
    desc "Set 'username' if not present derived from email"
    task :set_default => :environment do
      ::User.where("users.username IS NULL").find_each do |user|
        if un = user.email.split("@")[0]
          user.update_column(:username, un) unless user.username
        end
      end
    end
  end
end