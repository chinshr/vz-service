class Segment::ChunkSegment < ::Segment
  validates :document, presence: true
  validates :chunk, presence: true

  # The chunk's document association id not populated when document_id
  # is assigned to a chunk instance, so when the validation runs
  # against the chunk's document association, it will not pass.
  # E.g. Chunk::MechanicalTurkChunk.new(document_id: 1)
  def document_id=(value)
    self.document  = Document.find_by_id(value)
    chunk.document = self.document if chunk && self.document
    value
  end
end