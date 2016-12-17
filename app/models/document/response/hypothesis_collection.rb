class Document::Response::HypothesisCollection < Array
  include Model::Virtus::Collection

  collection_of Document::Response::Hypothesis
end
