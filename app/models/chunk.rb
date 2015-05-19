class Chunk < Document
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

  belongs_to :document
  belongs_to :ingest
  has_one :track, -> { where(is_master: false) },
    through: :tracking  # <- chunk track

  validates :document, presence: true
  validates :offset, presence: true

  filtered_scopes :sort_order, :reverse_sort, :any_of_types,
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
      order(self.arel_table[:position].send(param.first[1].to_sym).to_sql)
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
  scope :any_of_processing_status, -> (params) {where("documents.processing_status IN (?)", [params].flatten.map(&:to_s).
    map {|s| s.match(/^([\-]{,1}[0-9]+)$/) ? s : nil}.reject(&:blank?).uniq)}
  scope :none_of_processing_status, -> (params) {where("documents.processing_status NOT IN (?)", [params].flatten.map(&:to_s).
    map {|s| s.match(/^([\-]{,1}[0-9]+)$/) ? s : nil}.reject(&:blank?).uniq)}
  scope :any_of_positions, -> (params) {where(:position => params)}
  scope :any_of_ingest_iterations, -> (params) {where(:ingest_iteration => params)}
  scope :score_lt, -> (param) {where(self.arel_table[:score].lt(param))}
  scope :score_gt, -> (param) {where(self.arel_table[:score].gt(param))}
  scope :score_lteq, -> (param) {where(self.arel_table[:score].lteq(param))}
  scope :score_gteq, -> (param) {where(self.arel_table[:score].gteq(param))}
  scope :ingest_id, -> (param) {where(ingest_id: param)}
  scope :none_of_ingest_ids, -> (params) {where("documents.ingest_id NOT IN (?)", Array.wrap(params))}

  # private scopes
  scope :transcribed, -> {where(:processing_status => STATES[:transcribed])}
  scope :best, -> {
    joins("JOIN (SELECT position, MAX(score) AS max_score FROM documents p GROUP BY p.position) y ON y.position = documents.position AND y.max_score = documents.score").
    order(:position)
  }
  scope :ingest_chunks, -> { where("documents.document_id IS NOT NULL AND documents.ingest_id IS NOT NULL") }
  scope :document_chunks, -> { where("documents.document_id IS NOT NULL AND documents.ingest_id IS NULL") }

  before_save :set_start_and_end_at, :set_default_locale, on: :create

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
      Array.wrap(params).map do |p|
        class_name_for(p)
      end.reject(&:blank?)
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

    def rich_text
      self.all.map do |chunk|
        json = {"insert" => chunk.text, "attributes" => {"offset" => chunk.offset.to_f}}
        json["attributes"]["duration"] = chunk.duration.to_f if chunk.duration
        json["attributes"]["start_at"] = chunk.start_at.to_s if chunk.start_at
        json["attributes"]["end_at"]   = chunk.end_at.to_s if chunk.end_at
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
  end  ## class

  protected

  def set_start_and_end_at
    if ingest && ingest.upload && offset && duration
      self.start_at = ingest.upload.recorded_at + offset unless changes[:start_at]
      self.end_at   = self.start_at + duration unless changes[:end_at]
    end
  end

  def set_default_locale
    self.locale = document.locale if document && !changes[:locale]
  end
end
