class Plan::Config::Quota
  include Model::Virtus::ActiveModel

  attribute :id, String, default: :secure_random_id, lazy: true
  attribute :subject, String # e.g. 'media', transcription', 'upload', etc.
  attribute :unit, String # e.g. 'each', 'minute', 'year' etc.
  attribute :object, String # e.g. 'user', 'team', etc.
  attribute :denomination, String # e.g. 'month', 'day', 'organization', etc.
  attribute :value, String # e.g. nil, '1', '330', etc.

  # e.g. "minutes of transcription per user per month" -> "30"
  # e.g. "number of uploads per user per month" -> "300"
  # e.g. "minutes of transcription per media" -> "120"
  # e.g. "number of users per team"
  # e.g. "number of teams per organization"
  def humanize
    # => "{unit} of {subject} per {object} per {denomination}" -> {value}
  end
end
