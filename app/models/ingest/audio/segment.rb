class Ingest::Audio::Segment < ActiveRecord::Base
  self.table_name = "ingest_audio_segments"
  serialize :response, Hash
  
  belongs_to :ingest
  
  validates :ingest, presence: true
  validates :offset, presence: true
end
