module MultiDocumentChunk
  extend ActiveSupport::Concern

  included do
    has_many :document_segments, foreign_key: :chunk_id, dependent: :nullify,
      class_name: "Segment::ChunkSegment"
    has_many :documents, through: :document_segments, source: :document
  end

  module ClassMethods
  end
end