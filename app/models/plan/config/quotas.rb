class Plan::Config::Quotas
  include Model::Virtus::ActiveModel

  # attribute :unit, # e.g. 'each', 'minute', 'year' etc.
  # attribute :subject, # e.g. 'media', transcription', 'upload', etc.
  # attribute :object, # e.g. 'user', 'team', etc.
  # attribute :denomination, String, # e.g. 'month', 'day', 'year', etc.
  # attribute :value, String # e.g. '30', '330', etc.

  # => "{unit.pluralize} of {subject} per {object} per {denomination} = {value}"
  # e.g. "minutes of transcription per user per month"
  # e.g. "each of upload per user per month"
  # e.g. "each of user per team"
  # e.g. "each of teams per organization"
  attribute :minutes_of_transcription, Integer
  attribute :minutes_per_entity, String, default: 'user', lazy: true # e.g. 'user', 'team', etc.
  attribute :minutes_per_interval, String # e.g. 'month', 'year'

  attribute :number_of_uploads_per_user, Integer
  attribute :number_of_uploads_per_user_interval, String # e.g. 'month'
  attribute :number_of_users_per_team, Integer
  attribute :number_of_organizations, Integer
  attribute :number_of_teams_per_organization, Integer
end
