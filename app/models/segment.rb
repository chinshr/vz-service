class Segment < ActiveRecord::Base
  belongs_to :document
  belongs_to :chunk
  belongs_to :track
  belongs_to :ingest
end