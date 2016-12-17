class Document::Response::SpeakerSegment
  include Model::Virtus::ActiveModel

  attribute :id, String, default: :secure_random_id, lazy: true
  attribute :gender, String
  attribute :bandwidth, String
  attribute :start_time, Float
  attribute :end_time, Float
  attribute :duration, Float
  attribute :speaker_id, String
  attribute :speaker_model_uri, String
  attribute :speaker_supervector_hash, String
  attribute :speaker_mean_log_likelihood, Float
end
