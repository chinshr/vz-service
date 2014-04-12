class Document::Segment < ActiveRecord::Base
  self.table_name = "document_segments"
  serialize :response, Hash
  serialize :processing_errors, Array
  
  belongs_to :document
  
  validates :document, presence: true
  validates :offset, presence: true
  
  scope :any_of_type, lambda {|params| where(:type => type_for(params))}
  
  class << self
    def type_for(params)
      [params].flatten.map do |p|
        "Document::Segment::#{p.to_s.classify}"
      end
    end
  end
end
