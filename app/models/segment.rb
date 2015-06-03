class Segment < ActiveRecord::Base
  belongs_to :document
  belongs_to :chunk
  belongs_to :track
  belongs_to :ingest

  after_commit :destroy_track, on: :destroy

  protected

  def destroy_track
    track.destroy if track_id && Segment.where(track_id: track_id).count == 0
  end
end