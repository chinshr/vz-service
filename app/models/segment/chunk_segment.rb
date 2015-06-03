class Segment::ChunkSegment < ::Segment
  validates :document, presence: true
  validates :chunk, presence: true

  before_save :assign_chunk_track, on: :create

  def signal_assign_chunk_track!
    @assign_chunk_track = true
  end

  protected

  def assign_chunk_track
    if @assign_chunk_track
      self.track = chunk.track if chunk.track
    end
    true
  end
end