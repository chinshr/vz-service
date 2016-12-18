class Document::Response::Keyword
  include Model::Virtus::ActiveModel

  attribute :id, String, default: :secure_random_id, lazy: true
  attribute :text, String
  attribute :relevance, Float
  complex_attribute :emotions, Document::Response::Emotions
  complex_attribute :sentiment, Document::Response::Sentiment
end
