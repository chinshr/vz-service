class Segment < ApplicationRecord
  belongs_to :document
  belongs_to :chunk
  belongs_to :track
  belongs_to :ingest

  acts_as_paranoid

  after_destroy :destroy_track

  protected

  def destroy_track
    track.destroy if track && track_id && Segment.where(track_id: track_id).count == 0
  end
end
