class Document::Chunk < ActiveRecord::Base
  include Model::Filter
  self.table_name = "document_chunks"

  STATES = {
    :unprocessed         => Speech::AudioSplitter::AudioChunk::STATUS_UNPROCESSED,
    :built               => Speech::AudioSplitter::AudioChunk::STATUS_BUILT,
    :encoded             => Speech::AudioSplitter::AudioChunk::STATUS_ENCODED,
    :transcribed         => Speech::AudioSplitter::AudioChunk::STATUS_TRANSCRIBED,
    :build_error         => Speech::AudioSplitter::AudioChunk::STATUS_BUILD_ERROR,
    :encoding_error      => Speech::AudioSplitter::AudioChunk::STATUS_ENCODING_ERROR,
    :transcription_error => Speech::AudioSplitter::AudioChunk::STATUS_TRANSCRIPTION_ERROR
  }

  serialize :response, Hash
  serialize :processing_errors, Array

  belongs_to :document

  validates :document, presence: true
  validates :offset, presence: true

  # public scopes
  filtered_scopes :any_of_type
  scope :any_of_type, lambda {|params| where(:type => type_for(params))}
  # private scopes
  scope :transcribed, lambda {where(:processing_status => STATES[:transcribed])}
  scope :best, lambda {
    joins("JOIN (SELECT position, MAX(score) AS max_score FROM document_chunks p GROUP BY p.position) y ON y.position = document_chunks.position AND y.max_score = document_chunks.score").
    order(:position)
  }
  scope :worst, lambda {
    joins("JOIN (SELECT position, MIN(score) AS min_score FROM document_chunks p GROUP BY p.position) y ON y.position = document_chunks.position AND y.min_score = document_chunks.score").
    order(:position)
  }

  class << self
    def type_for(params)
      [params].flatten.map do |p|
        "Document::Chunk::#{p.to_s.classify}"
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
        json = {"insert" => chunk.text, "attributes" => {"offset" => chunk.offset}}
        json["attributes"]["duration"] = chunk.duration if chunk.duration
        json["attributes"]["start_time"] = chunk.start_time if chunk.start_time
        json["attributes"]["end_time"] = chunk.end_time if chunk.end_time
        json
      end
    end
  end
end
