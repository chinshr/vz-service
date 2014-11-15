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

  def mp3_stream_url
    s3 = AWS::S3.new
    object = s3.buckets[APP_CONFIG['S3_OUTBOUND_BUCKET']].objects[s3_mp3_key]
    object.url_for(:get, {:expires => 20.minutes.from_now, :secure => true}).to_s
  end

end
