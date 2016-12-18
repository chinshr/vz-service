class Document::Response::Entity
  include Model::Virtus::ActiveModel

  attribute :id, String, default: :secure_random_id, lazy: true
  attribute :type, String
  attribute :relevance, Float
  attribute :count, Integer
  attribute :text, String

  complex_attribute :disambiguated, Document::Response::Disambiguated
end
