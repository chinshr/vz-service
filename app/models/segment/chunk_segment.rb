class Segment::ChunkSegment < ::Segment
  validates :document, presence: true
  validates :chunk, presence: true

  before_save :assign_chunk_track, on: :create

  # The chunk's document association id not populated when document_id
  # is assigned to a chunk instance, so when the validation runs
  # against the chunk's document association, it will not pass.
  # E.g. Chunk::MechanicalTurkChunk.new(document_id: 1)
  def document_id=(value)
    self.document  = Document.find_by_id(value)
    chunk.document = self.document if chunk && self.document
    value
  end

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