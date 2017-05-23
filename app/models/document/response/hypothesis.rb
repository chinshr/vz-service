class Document::Response::Hypothesis
  include Model::Virtus::ActiveModel

  attribute :id, String, default: :secure_random_id, lazy: true
  attribute :utterance, String
  attribute :confidence, Float
end
