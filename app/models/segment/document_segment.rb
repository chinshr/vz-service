class Segment::DocumentSegment < ::Segment
  validates :document, presence: true
  validates :track, presence: true
end