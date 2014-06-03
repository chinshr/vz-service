class Document::Chunk < ActiveRecord::Base
  self.table_name = "document_chunks"
  serialize :response, Hash
  serialize :processing_errors, Array
  
  belongs_to :document
  
  validates :document, presence: true
  validates :offset, presence: true
  
  scope :any_of_type, lambda {|params| where(:type => type_for(params))}
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
    
    # E.g. @document.chunks.best.text => "this is the best chunked text"
    def text
      self.all.map(&:text).join(" ").to_s
    end
  end
end
