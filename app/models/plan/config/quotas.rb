class Plan::Config::Quotas
  include Model::Virtus::ActiveModel

  attribute :uploads_per_user_per_month, Integer
  attribute :minutes_per_media, Integer
  attribute :number_of_users_per_team, Integer
  attribute :number_of_organizations, Integer
  attribute :number_of_teams_per_organization, Integer
end
