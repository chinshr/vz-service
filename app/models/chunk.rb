class Chunk < ::Document
  STATES = {unprocessed: 0, built: 1, encoded: 2,
    transcribed: 3, build_error: -1, encoding_error: -2,
    transcription_error: -3}

  delegate :title, to: :document, allow_nil: true
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

  before_save :set_default_locale, on: :create
  after_validation :save_master_chunk_segment_and_track

  class << self
    def slug_id_length; 40; end

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

    # Encode chunk information into a rich-text attribute.
    # See: https://github.com/ottypes/rich-text
    #
    # We have to build an attribute syntax based on:
    #
    #   * uid
    #   * time: start-time / end-time
    #   * profile id
    #   * segment color
    #   * score
    #
    # to build formatted segment structures like this:
    #
    #     <uid>^<start-time>-<end-time>@<profile-id>#<color>
    #
    # E.g.
    #
    #     {"attributes": {"segment": "c4ea2bad-6f84-4b6c-869b-8ddcd4128d83+t1_52-3_41+s0_976"}}
    #     {"attributes": {"segment": "c4ea2bad-6f84-4b6c-869b-8ddcd4128d83+t1_52-3_41+s0_75"}}
    #
    def rich_text
      rt = self.all.map do |chunk|
        json = {"insert" => chunk.text, "attributes" => {}}
        json["attributes"]["segment"] = chunk.segment_id
        json
      end
      # add spaces in between junks
      rt = rt.zip((rt.length - 1).times.map {{"insert" => " "}}).flatten.compact
      # return ops
      {"ops" => rt}
    end

    def segment_id(uid, start_time = nil, end_time = nil, score = nil, options = {})
      result =  "#{uid}"
      result += "-t#{sprintf('%.2f', start_time)}-#{sprintf('%.2f', end_time)}".gsub('.', '_') if start_time && end_time
      result += "-s#{sprintf('%.3f', score)}".gsub('.', '_') if score
      result
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

  def master_segment; master_chunk_segment; end

  def segment_id
    self.class.segment_id(uid, start_time, end_time, score)
  end

  def start_time
    self[:start_time] || offset
  end

  def end_time
    self[:end_time] || (offset + (duration || 0))
  end

  # override from document
  def score
    self[:score]
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

  def title_and_slug_id
    slug_id
  end

  def update_chunks_from_segments
    # overwrite, NOOP, and return
    true
  end

end
