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

  namespace :api do
    namespace :access do
      desc "Generate access tokens in case they are missing"
      task :generate => :environment do
        ::User.find_each do |user|
          if user.send(:generate_access_token?)
            user.send(:generate_access_id) and user.send(:generate_access_secret)
            user.update_attributes({access_id: user.access_id, access_secret: user.access_secret})
          end
        end
      end

      desc "Force generate access tokens"
      task :force_generate => :environment do
        ::User.find_each do |user|
          user.send(:generate_access_id) and user.send(:generate_access_secret)
          user.update_attributes({access_id: user.access_id, access_secret: user.access_secret})
        end
      end
    end
  end
end