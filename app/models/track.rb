class Track < ActiveRecord::Base
  include Model::Filter
  include Model::Uid

  has_many :segments, foreign_key: :track_id, dependent: :nullify

  acts_as_paranoid

  after_destroy :perform_delete_job

  # public scopes
  filtered_scopes :sort_order, :reverse_sort, :any_of_types, :none_of_types
  scope :sort_order, -> (param) {
    case param.first[0]  # E.g. get first key of {"id"=>"asc"}
    when "id"
      order(self.arel_table[:id].send(param.first[1].to_sym).to_sql)
    else
      raise ArgumentError, "Ignored unrecognized value 'sort_order[]=#{param}'."
    end
  }
  scope :reverse_sort, -> (param) { all.reverse_order if Model::Helper.booleanize(param) }
  scope :any_of_types, -> (params) {where("tracks.type IN (?)", class_names_for(params))}
  scope :none_of_types, -> (params) {where("tracks.type NOT IN (?)", class_names_for(params))}

  class << self
    # Type casts to the class specified in :type parameter
    #
    # E.g.
    #
    #   Track.new(:type => :document, ...) -> Track::DocumentTrack
    #   Track.new(:type => :chunk_track, ...) -> Track::ChunkTrack
    #   Track.create(:type => "Track::DocumentTrack", ...) -> Track::DocumentTrack
    #
    def new_with_cast(*a, &b)
      if (h = a.first).is_a? Hash and (type = h[:type] || h['type']) and
        (k = type.class == Class ? type : promote_track_class_for(type, h)) != self
        raise NameError, "unknown type for Track" if !k || !(k < self)
        instance = k.new(*a, &b)
        return instance
      end
      new_without_cast(*a, &b)
    end
    alias_method_chain :new, :cast

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

    private

    # E.g. "chunk" => Track::ChunkTrack
    def class_for(type)
      class_name = class_name_for(type)
      class_name.constantize if class_name
    end

    # E.g.
    #
    #    "document_track" -> "Track::DocumentTrack"
    #    "document" -> "Track::DocumentTrack"
    #    "Track::DocumentTrack" -> "Track::DocumentTrack"
    #
    def class_name_for(name)
      class_name = if name.to_s.index("::")
        "#{name}"
      else
        name.to_s.index("_track") ? "Track::#{(name.to_s.classify)}" : "Track::#{(name.to_s.classify)}Track"
      end
      class_name.constantize.name
    rescue NameError
      nil
    end

    def class_names_for(params)
      Array.wrap(params).map {|p| class_name_for(p)}.reject(&:blank?)
    end

    def promote_track_class_for(name, attributes = {})
      attributes.symbolize_keys! if attributes.respond_to?(:symbolize_keys!)
      klass = class_for(name)
      raise NameError, "unknown Track subclass '#{name}'" unless klass
      attributes[:type] = klass.name
      klass
    end

  end  # class methods

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
    object.url_for(:get, {expires: 2.minutes.from_now, secure: Rails.env.production?,
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
    object.url_for(:get, {expires: 2.minutes.from_now, secure: Rails.env.production?,
      response_content_type: "application/json"}).to_s
  end

  protected

  def perform_delete_job
    Track::DeleteJob.perform_later(self.id)
  end

  def s3_origin_bucket_name
    bucket = APP_CONFIG['S3_OUTBOUND_BUCKET']
    bucket = bucket.gsub(/\/?(.*)/, '\1')
    bucket
  end

end
