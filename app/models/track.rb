class Track < ActiveRecord::Base
  validates :s3_url, presence: true

  has_one :ingest
  has_one :document, :through => :ingest, :source => :ingestable, :source_type => "Document"
  
  def s3_key
    s3_url ? s3_url.split("/").last : nil
  end

  def s3_mp3_key
    s3_mp3_url ? s3_mp3_url.split("/").last : nil
  end
  
end
