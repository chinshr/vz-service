class Tracking < ActiveRecord::Base
  belongs_to :document
  belongs_to :track
  belongs_to :ingest

  validates :document, presence: true
  validates :track, presence: true
end