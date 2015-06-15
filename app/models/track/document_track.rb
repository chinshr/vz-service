class Track::DocumentTrack < ::Track
  delegate :ingest_id, to: :document_segment, allow_nil: true
  delegate :document_id, to: :document_segment, allow_nil: true

  has_one :document_segment, -> { where(is_master: true) }, foreign_key: :track_id, dependent: :nullify, class_name: "Segment::DocumentSegment"
  has_one :ingest, through: :document_segment, source: :ingest
  has_one :document, through: :document_segment, source: :document

  before_validation :set_document
  before_validation :mark_duplicates_for_destruction, on: :create
  after_commit :destroy_duplicate_tracks

  def document_segment
    super || build_document_segment(track: self)
  end

  def document
    super || (document_id ? ::Document.find_by_id(document_id) : nil)
  end

  protected

  def set_document
    self.document ||= ingest.document if ingest && ingest.document
  end

  def mark_duplicates_for_destruction
    @duplicate_document_segments = []
    Segment::DocumentSegment.where("segments.document_id = ?", document_id).each do |segment|
      @duplicate_document_segments << segment
    end if document_id
  end

  def destroy_duplicate_tracks
    @duplicate_document_segments.each do |segment|
      if segment && segment.track && segment.track != self
        segment.track.destroy
        segment.destroy
      end
    end if @duplicate_document_segments
  end
end