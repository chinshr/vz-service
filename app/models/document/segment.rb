class Document::Segment < ActiveRecord::Base
  self.table_name = "document_segments"
  serialize :response, Hash
  
  belongs_to :document
  
  validates :document, presence: true
  validates :offset, presence: true
end
