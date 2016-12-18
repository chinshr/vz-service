class Document::Response::Disambiguated
  include Model::Virtus::ActiveModel

  attribute :id, String, default: :secure_random_id, lazy: true
  attribute :sub_type, Array[String], default: []
  attribute :name, String
  attribute :geo, String
  attribute :website, String
  attribute :dbpedia, String
  attribute :freebase, String
  attribute :opencyc, String
  attribute :yago, String
end
