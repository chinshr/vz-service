class Document < ActiveRecord::Base
  has_many :ingests, class_name: "Document::Ingest"
end
