class Document::Response::EntityCollection < Array
  include Model::Virtus::Collection

  collection_of Document::Response::Entity
end
