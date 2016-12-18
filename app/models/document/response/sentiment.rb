class Document::Response::Sentiment
  include Model::Virtus::ActiveModel

  attribute :type, String
  attribute :score, Float
end
