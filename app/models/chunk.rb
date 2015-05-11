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

  filtered_scopes :sort_order, :reverse_sort, :any_of_type,
    :any_of_processing_status, :none_of_processing_status,
    :any_of_position, :any_of_ingest_iteration
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
    else
      raise ArgumentError, "Ignored unrecognized value 'sort_order[]=#{param}'."
    end
  }
  scope :reverse_sort, -> (param) {all.reverse_order if Model::Helper.booleanize(param)}
  scope :any_of_type, -> (params) {where("documents.type IN (?) OR documents.type IN (?)", type_for(params), params)}
  scope :any_of_processing_status, -> (params) {where("documents.processing_status IN (?)", [params].flatten.map(&:to_s).
    map {|s| s.match(/^([\-]{,1}[0-9]+)$/) ? s : nil}.reject(&:blank?).uniq)}
  scope :none_of_processing_status, -> (params) {where("documents.processing_status NOT IN (?)", [params].flatten.map(&:to_s).
    map {|s| s.match(/^([\-]{,1}[0-9]+)$/) ? s : nil}.reject(&:blank?).uniq)}
  scope :any_of_position, -> (params) {where(:position => params)}
  scope :any_of_ingest_iteration, -> (params) {where(:ingest_iteration => params)}

  # private scopes
  scope :transcribed, -> {where(:processing_status => STATES[:transcribed])}
  scope :best, -> {
    joins("JOIN (SELECT position, MAX(score) AS max_score FROM documents p GROUP BY p.position) y ON y.position = documents.position AND y.max_score = documents.score").
    order(:position)
  }
  scope :ingest_chunks, -> { where("documents.document_id IS NOT NULL AND documents.ingest_id IS NOT NULL") }
  scope :document_chunks, -> { where("documents.document_id IS NOT NULL AND documents.ingest_id IS NULL") }

  before_save :set_start_and_end_at, :set_locale, on: :create

  class << self
    def slug_length; 40; end

    def policy_class
      ChunkPolicy
    end

    def type_for(params)
      [params].flatten.map do |p|
        "Chunk::#{p.to_s.classify}"
      end
    end

    # Document::Chunk.type_from_engine_class_for(audio.engine.class) => "Document::Chunk::GoogleSpeech"
    def type_from_engine_class_for(klass)
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
  end  ## class

  protected

  def set_start_and_end_at
    if ingest && ingest.upload && offset && duration
      self.start_at = ingest.upload.recorded_at + offset
      self.end_at   = self.start_at + duration
    end
  end

  def set_locale
    self.locale = document.locale if document
  end
end
