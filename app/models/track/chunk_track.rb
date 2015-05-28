class Track::ChunkTrack < ::Track
  # delegate :chunk_id, to: :segment, allow_nil: true

  has_many :chunk_segments, foreign_key: :track_id, dependent: :nullify, class_name: "Segment::ChunkSegment"
  has_many :chunks, through: :chunk_segments, source: :chunk

  before_validation :set_chunk_segments_document

  def ingest=(value)
    # dummy setter
  end

  def ingest_id=(value)
    # dummy setter
  end

  protected

  def set_chunk_segments_document
    chunk_segments.each do |segment|
      segment.document ||= segment.chunk.document if segment.chunk && segment.chunk.document
    end
  end
end