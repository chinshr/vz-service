class Ingest < ActiveRecord::Base
  belongs_to :upload
  belongs_to :ingestable, polymorphic: true, touch: true
  
  validates :upload, presence: true, associated: true
  validates :ingestable, presence: true
end
