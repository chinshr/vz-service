class Track < ActiveRecord::Base
  include Model::Filter
  include Model::Uid

  delegate :ingest_id, to: :segment, allow_nil: true
  delegate :document_id, to: :segment, allow_nil: true
  delegate :chunk_id, to: :segment, allow_nil: true
  delegate :offset, to: :trackable, allow_nil: true
  delegate :duration, to: :trackable, allow_nil: true
  delegate :start_at, to: :trackable, allow_nil: true
  delegate :end_at, to: :trackable, allow_nil: true

  has_one :segment, foreign_key: :track_id, dependent: :nullify
  has_one :ingest, through: :segment, source: :ingest
  has_one :document, through: :segment, source: :document
  has_one :chunk, through: :segment, source: :chunk

  validates :s3_url, presence: true

  # public scopes
  filtered_scopes :sort_order, :reverse_sort, :is_master
  scope :sort_order, -> (param) {
    case param.first[0]  # E.g. get first key of {"id"=>"asc"}
    when "id"
      order(self.arel_table[:id].send(param.first[1].to_sym).to_sql)
    else
      raise ArgumentError, "Ignored unrecognized value 'sort_order[]=#{param}'."
    end
  }
  scope :reverse_sort, -> (param) { all.reverse_order if Model::Helper.booleanize(param) }
  scope :is_master, -> (param) { where(is_master: Model::Helper.booleanize(param))}

  class << self
    def generate_uid
      SecureRandom.uuid
    end

    # TODO: refactor obsolete
    def policy_class
      TrackPolicy
    end

    def s3_url_to_key(s3_url)
      path = URI.parse(s3_url).path.split("/").reject(&:blank?) if s3_url
      File.join(path.slice(1..-1)) if path && path.length > 0
    rescue URI::InvalidURIError => ex
      nil
    end
  end

  def trackable
    if segment.is_a?(Segment::DocumentSegment) || is_master?
      segment.document
    elsif segment.is_a?(Segment::ChunkSegment) || !is_master?
      segment.chunk
    end
  end

  def trackable=(value)
    if segment.is_a?(Segment::DocumentSegment) || is_master?
      segment.document = value
    elsif segment.is_a?(Segment::ChunkSegment) || !is_master?
      segment.chunk = value
    end
  end

  def trackable_id
    trackable.try(:id)
  end

  def s3_key
    self.class.s3_url_to_key(s3_url)
  end

  # Turns private `s3_mp3_url` into a public streaming URL
  # E.g. http://vz-dev-origin.s3.amazonaws.com/d28f7815-1916-4a82-87f3-1ec1c4c667f1/6oytipuc99.ac2.ab128k.mp3?AWSAccessKeyId=AKIAJB7Z3FGKOUXPZ7ZQ&Expires=1431633540&Signature=fPjk686wUZDp7dQvfq%2FJSuyUD04%3D&response-content-type=audio%2Fmpeg
  # Help: http://docs.aws.amazon.com/AWSRubySDK/latest/AWS/S3/S3Object.html#url_for-instance_method
  #
  # Configure AWS S3 Bucket Policy for public access:
  #
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
  #
  def mp3_stream_url
    s3 = AWS::S3.new
    object = s3.buckets[s3_origin_bucket_name].objects[s3_mp3_key]
    object.url_for(:get, {expires: 20.minutes.from_now, secure: false,
      response_content_type: "audio/mpeg"}).to_s
  end

  # E.g. "d155ef63-0e83-4661-b672-955fd7578a73/guj58l1j7l.ac2.ab128k.mp3"
  def s3_mp3_key
    self.class.s3_url_to_key(s3_mp3_url)
  end

  def s3_waveform_json_key
    self.class.s3_url_to_key(s3_waveform_json_url)
  end

  def waveform_json_stream_url
    s3 = AWS::S3.new
    object = s3.buckets[s3_origin_bucket_name].objects[s3_waveform_json_key]
    object.url_for(:get, {expires: 20.minutes.from_now, secure: false,
      response_content_type: "application/json"}).to_s
  end

  protected

  def s3_origin_bucket_name
    bucket = APP_CONFIG['S3_OUTBOUND_BUCKET']
    bucket = bucket.gsub(/\/?(.*)/, '\1')
    bucket
  end
end
