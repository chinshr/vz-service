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
end