class Chunk < ::Document
  STATES = {
    :unprocessed         => Speech::AudioSplitter::AudioChunk::STATUS_UNPROCESSED,
    :built               => Speech::AudioSplitter::AudioChunk::STATUS_BUILT,
    :encoded             => Speech::AudioSplitter::AudioChunk::STATUS_ENCODED,
    :transcribed         => Speech::AudioSplitter::AudioChunk::STATUS_TRANSCRIBED,
    :build_error         => Speech::AudioSplitter::AudioChunk::STATUS_BUILD_ERROR,
    :encoding_error      => Speech::AudioSplitter::AudioChunk::STATUS_ENCODING_ERROR,
    :transcription_error => Speech::AudioSplitter::AudioChunk::STATUS_TRANSCRIPTION_ERROR
  }

  delegate :title, to: :document
  delegate :document_id, to: :master_chunk_segment, allow_nil: true
  delegate :document_id=, to: :master_chunk_segment, allow_nil: true
  delegate :ingest_id, to: :master_chunk_segment, allow_nil: true
  delegate :ingest_id=, to: :master_chunk_segment, allow_nil: true
  delegate :track_id, to: :master_chunk_segment, allow_nil: true
  delegate :track_id=, to: :master_chunk_segment, allow_nil: true
  delegate :position, to: :master_chunk_segment, allow_nil: true
  delegate :position=, to: :master_chunk_segment, allow_nil: true

  has_one :master_chunk_segment, -> { where(is_master: true) }, foreign_key: :chunk_id, dependent: :destroy, class_name: "Segment::ChunkSegment"
  has_one :document, through: :master_chunk_segment, source: :document
  has_one :ingest, through: :master_chunk_segment, source: :ingest
  has_one :track, through: :master_chunk_segment, class_name: "Track::ChunkTrack"

  has_many :parent_segments, foreign_key: :chunk_id, dependent: :nullify,
    class_name: "Segment::ChunkSegment"
  has_many :documents, through: :parent_segments, source: :document

  validates :document, presence: true
  validates :offset, presence: true

  filtered_scopes :sort_order, :reverse_sort, :any_of_types, :none_of_types,
    :any_of_processing_status, :none_of_processing_status,
    :any_of_positions, :any_of_ingest_iterations, :score_lt, :score_gt,
    :score_lteq, :score_gteq, :ingest_id, :none_of_ingest_ids
  scope :sort_order, -> (param) {
    case param.first[0]  # E.g. get first key of {"id"=>"asc"}
    when "id"
      order(self.arel_table[:id].send(param.first[1].to_sym).to_sql)
    when "created_at"
      order(self.arel_table[:created_at].send(param.first[1].to_sym).to_sql)
    when "position"
      joins(:master_chunk_segment).order("segments.position #{param.first[1]}")
    when "score"
      order(self.arel_table[:score].send(param.first[1].to_sym).to_sql)
    when "random"
      order("random()")
    else
      raise ArgumentError, "Ignored unrecognized value 'sort_order[]=#{param}'."
    end
  }
  scope :reverse_sort, -> (param) {all.reverse_order if Model::Helper.booleanize(param)}
  scope :any_of_types, -> (params) {where("documents.type IN (?)", class_names_for(params))}
  scope :none_of_types, -> (params) {where("documents.type NOT IN (?)", class_names_for(params))}
  scope :any_of_processing_status, -> (params) {where("documents.processing_status IN (?)", [params].flatten.map(&:to_s).
    map {|s| s.match(/^([\-]{,1}[0-9]+)$/) ? s : nil}.reject(&:blank?).uniq)}
  scope :none_of_processing_status, -> (params) {where("documents.processing_status NOT IN (?)", [params].flatten.map(&:to_s).
    map {|s| s.match(/^([\-]{,1}[0-9]+)$/) ? s : nil}.reject(&:blank?).uniq)}
  scope :any_of_positions, -> (params) {joins(:master_chunk_segment).where("segments.position IN (?)", Array.wrap(params))}
  scope :any_of_ingest_iterations, -> (params) {where(:ingest_iteration => params)}
  scope :score_lt, -> (param) {where(self.arel_table[:score].lt(param))}
  scope :score_gt, -> (param) {where(self.arel_table[:score].gt(param))}
  scope :score_lteq, -> (param) {where(self.arel_table[:score].lteq(param))}
  scope :score_gteq, -> (param) {where(self.arel_table[:score].gteq(param))}
  scope :ingest_id, -> (param) {joins(:master_chunk_segment).where("segments.ingest_id = ?", param)}
  scope :none_of_ingest_ids, -> (params) {joins(:master_chunk_segment).where("segments.ingest_id NOT IN (?)", Array.wrap(params))}

  # private scopes
  scope :transcribed, -> {where(:processing_status => STATES[:transcribed])}

=begin
  scope :best, -> {
    joins("INNER JOIN segments ys ON ys.chunk_id = documents.id AND ys.type IN ('Segment::ChunkSegment')").
    joins("JOIN (SELECT ps.position AS position, MAX(score) AS max_score FROM documents p INNER JOIN segments ps ON ps.chunk_id = p.id AND ps.document_id = 163 AND ps.type IN ('Segment::ChunkSegment') GROUP BY ps.position) y ON y.position = ys.position AND y.max_score = documents.score").
    order("ys.position")
  }
=end


  before_save :set_default_locale, on: :create
  after_validation :save_master_chunk_segment_and_track

  class << self
    def slug_length; 40; end

    # Type casts to the class specified in :type parameter
    #
    # E.g.
    #
    #   Chunk.new(:type => :google_speech, ...) -> Chunk::GoogleSpeechChunk
    #   Chunk.new(:type => :google_speech_chunk, ...) -> Chunk::GoogleSpeechChunk
    #   Chunk.create(:type => "Chunk::GoogleSpeechChunk", ...) -> Chunk::GoogleSpeechChunk
    #
    def new_with_cast(*a, &b)
      if (h = a.first).is_a? Hash and (type = h[:type] || h['type']) and
        (k = type.class == Class ? type : promote_upload_class_for(type, h)) != self
        raise NameError, "unknown type for Chunk" if !k || !(k < self)
        instance = k.new(*a, &b)
        return instance
      end
      new_without_cast(*a, &b)
    end
    alias_method_chain :new, :cast

    # TODO: obsolete
    def policy_class
      ChunkPolicy
    end

    def class_names_for(params)
      Array.wrap(params).map {|p| class_name_for(p)}.reject(&:blank?)
    end

    # Document::Chunk.class_name_from_engine_class_for(audio.engine.class) => "Document::Chunk::GoogleSpeechChunk"
    def class_name_from_engine_class_for(klass)
      chunk_class = self.subclasses.find {|cc| cc.respond_to?(:engine_class_name) && cc.engine_class_name == klass.to_s}
      chunk_class.name if chunk_class
    end

    # E.g. @document.chunks.best.text => "this is the best chunked text"
    def text
      self.all.map(&:text).join(" ").to_s
    end

    # See https://github.com/ottypes/rich-text
    def rich_text
      self.all.map do |chunk|
        json = {"insert" => chunk.text, "attributes" => {}}
        json["attributes"]["start"]   = chunk.offset.to_f if chunk.offset
        json["attributes"]["end"]     = (chunk.offset + chunk.duration).to_f if chunk.duration
        json["attributes"]["segment"] = chunk.uid
        # json["attributes"]["duration"] = chunk.duration.to_f if chunk.duration
        # json["attributes"]["start_at"] = chunk.start_at.to_s if chunk.start_at
        # json["attributes"]["end_at"]   = chunk.end_at.to_s if chunk.end_at
        json
      end
    end

    private

    # E.g. "audio" => Upload::AudioUpload
    def class_for(type)
      class_name = class_name_for(type)
      class_name.constantize if class_name
    end

    # E.g.
    #
    #    "pocketsphinx_chunk" -> "Chunk::PocketsphinxChunk"
    #    "pocketsphinx" -> "Chunk::PocketsphinxChunk"
    #    "Chunk::PocketsphinxChunk" -> "Chunk::PocketsphinxChunk"
    #
    def class_name_for(name)
      class_name = if name.to_s.index("::")
        "#{name}"
      else
        name.to_s.index("_chunk") ? "Chunk::#{(name.to_s.classify)}" : "Chunk::#{(name.to_s.classify)}Chunk"
      end
      class_name.constantize.name
    rescue NameError
      nil
    end

    def promote_upload_class_for(name, attributes = {})
      attributes.symbolize_keys! if attributes.respond_to?(:symbolize_keys!)
      klass = class_for(name)
      raise NameError, "unknown Chunk subclass '#{name}'" unless klass
      attributes[:type] = klass.name
      klass
    end
  end  # class

  def master_chunk_segment
    super || build_master_chunk_segment(chunk: self)
  end

  def document
    super || (document_id ? ::Document.find_by_id(document_id) : nil)
  end

  def master_segment
    master_chunk_segment
  end

  protected

  def set_default_locale
    self.locale = document.locale if document && !changes[:locale]
  end

  def save_master_chunk_segment_and_track
    needs_update = false
    if master_chunk_segment.track && (master_chunk_segment.track.new_record? || master_chunk_segment.track.changed?) && master_chunk_segment.track.valid?
      needs_update = true
      master_chunk_segment.track.save
    end

    if (needs_update || master_chunk_segment.new_record? || master_chunk_segment.changed?) && master_chunk_segment.valid?
      master_chunk_segment.save
    end
  end

  # Override from superclass
  def after_add_child_segment(segment)
    super
    if new_record?
      segment.ingest ||= self.ingest
      segment.track  ||= self.track
    end
  end
end
