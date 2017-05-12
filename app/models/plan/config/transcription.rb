class Plan::Config::Transcription
  include Model::Virtus::ActiveModel

  attribute :engine, String
  attribute :quality, String
end
