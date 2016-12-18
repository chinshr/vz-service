class Document::Response::Emotions
  include Model::Virtus::ActiveModel

  attribute :joy, Float
  attribute :fear, Float
  attribute :anger, Float
  attribute :disgust, Float
  attribute :sadness, Float
end
