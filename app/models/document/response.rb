class Document::Response
  include Model::Virtus::ActiveModel

  VERSION = "1.0.0"

  attribute :version, String, default: :current_version, lazy: true
  attribute :id, String, default: :secure_random_id, lazy: true
  attribute :status, Integer
  attribute :external_status, String
  attribute :errors, Array[String], default: []

  collection_attribute :keywords, Document::Response::KeywordCollection[Document::Response::Keyword], default: []
  collection_attribute :entities, Document::Response::EntityCollection[Document::Response::Entity], default: []

  # chunk

  collection_attribute :hypotheses, Document::Response::HypothesisCollection[Document::Response::Hypothesis], default: []
  collection_attribute :words, Document::Response::WordCollection[Document::Response::Word], default: []
  complex_attribute :speaker_segment, Document::Response::SpeakerSegment

  def self.dump(values)
    values.to_hash
  end

  def self.load(values)
    new(values)
  end

  private

  def current_version
    VERSION
  end
end
