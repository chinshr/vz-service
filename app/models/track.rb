class Track < ActiveRecord::Base
  validates :s3_url, presence: true

  has_one :ingest
  has_one :document, :through => :ingest, :source => :ingestable, :source_type => "Document"
end
