class Upload < ActiveRecord::Base
  has_one :ingests, class_name: "Document::Ingest"
end
