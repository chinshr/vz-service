class Document::Response::KeywordCollection < Array
  include Model::Virtus::Collection

  collection_of Document::Response::Keyword
end
