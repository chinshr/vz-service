class Document::Ingest < ActiveRecord::Base
  self.table_name = "document_ingests"

  belongs_to :upload
  belongs_to :document
end
