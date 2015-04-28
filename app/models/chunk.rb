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

  belongs_to :ingest
  delegate :track, to: :ingest
  validates :ingest, presence: true
  validates :offset, presence: true

  filtered_scopes :sort_order, :reverse_sort, :any_of_type,
    :any_of_processing_status, :none_of_processing_status
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
  scope :any_of_type, -> (params) {where(:type => type_for(params))}
  scope :any_of_processing_status, -> (params) {where("documents.processing_status IN (?)", [params].flatten.map(&:to_s).
    map {|s| s.match(/^([\-]{,1}[0-9]+)$/) ? s : nil}.reject(&:blank?).uniq)}
  scope :none_of_processing_status, -> (params) {where("documents.processing_status NOT IN (?)", [params].flatten.map(&:to_s).
    map {|s| s.match(/^([\-]{,1}[0-9]+)$/) ? s : nil}.reject(&:blank?).uniq)}

  # private scopes
  scope :transcribed, -> {where(:processing_status => STATES[:transcribed])}
  scope :best, -> {
    joins("JOIN (SELECT position, MAX(score) AS max_score FROM documents p GROUP BY p.position) y ON y.position = documents.position AND y.max_score = documents.score").
    order(:position)
  }

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
      chunk_class = self.subclasses.find {|cc| cc.engine_class_name == klass.to_s}
      chunk_class.name if chunk_class
    end

    # E.g. @document.chunks.best.text => "this is the best chunked text"
    def text
      self.all.map(&:text).join(" ").to_s
    end

    def rich_text
      self.all.map do |chunk|
        json = {"insert" => chunk.text, "attributes" => {"offset" => chunk.offset.to_f}}
        json["attributes"]["duration"]   = chunk.duration.to_f if chunk.duration
        json["attributes"]["start_time"] = chunk.start_time.to_f if chunk.start_time
        json["attributes"]["end_time"]   = chunk.end_time.to_f if chunk.end_time
        json
      end
    end
  end  ## class

  def title
    ingest.try(:document).try(:title)
  end

  protected

  def canonical_document?
    false
  end
end
