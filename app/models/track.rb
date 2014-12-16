class Track < ActiveRecord::Base
  include Model::Filter

  validates :s3_url, presence: true

  has_one :ingest
  has_one :document, :through => :ingest, :source => :ingestable, :source_type => "Document"

  # public scopes
  filtered_scopes :sort_order, :reverse_sort
  scope :sort_order, lambda {|param|
    case param.first[0]  # E.g. get first key of {"id"=>"asc"}
    when "id"
      order(self.arel_table[:id].send(param.first[1].to_sym).to_sql)
    else
      raise ArgumentError, "Ignored unrecognized value 'sort_order[]=#{param}'."
    end
  }
  scope :reverse_sort, lambda {|param| all.reverse_order if Model::Helper.booleanize(param)}

  def s3_key
    s3_url ? s3_url.split("/").last : nil
  end

  def s3_mp3_key
    s3_mp3_url ? s3_mp3_url.split("/").last : nil
  end

  # http://docs.aws.amazon.com/AWSRubySDK/latest/AWS/S3/S3Object.html#url_for-instance_method
  # dropbox-dev.voyzes.com -> http://s3.amazonaws.com/dropbox-dev.voyzes.com/6s8l775jqc.128.mp3?AWSAccessKey…OUXPZ7ZQ&Expires=1418179793&Signature=ihPMw6fUy%2FW%2BG4V%2FSQWcws3izBk%3D
  # secure-dev.voyzes.com  -> http://s3.amazonaws.com/secure-dev.voyzes.com/6s8l775jqc.128.mp3
  def mp3_stream_url
    s3 = AWS::S3.new
    object = s3.buckets[APP_CONFIG['S3_OUTBOUND_BUCKET']].objects[s3_mp3_key]
    object.url_for(:get, {:expires => 20.minutes.from_now, :secure => false, :response_content_type => "audio/mpeg"}).to_s
  end

  # AWS S3 Bucket Policy for public access:
  # {
  # "Version": "2012-10-17",
  # "Statement": [
  #   {
  #     "Sid": "AddPerm",
  #     "Effect": "Allow",
  #     "Principal": "*",
  #     "Action": "s3:GetObject",
  #     "Resource": "arn:aws:s3:::voyzes-dev-private/*"
  #   }
  # ]
  # }

end
