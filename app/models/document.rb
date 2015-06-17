require "fuzzy_match"
require "matrix"

class Document < ActiveRecord::Base
  include Model::Filter
  include Model::Uid

  PRIVACY_SETTINGS = {'public' => 0, 'private' => 1, 'unlisted' => 2}

  delegate :duration, to: :track, allow_nil: true
  delegate :duration=, to: :track, allow_nil: true
  delegate :start_at, to: :track, allow_nil: true
  delegate :end_at, to: :track, allow_nil: true

  belongs_to :user
  has_many :ingests, foreign_key: :document_id
  has_many :segments, foreign_key: :document_id, dependent: :destroy
  has_many :child_segments, foreign_key: :document_id, :after_add => :after_add_child_segment,
    dependent: :destroy, class_name: "Segment::ChunkSegment"
  has_many :chunks, through: :child_segments, source: :chunk do
    def create(chunk_attributes)
      Chunk.create({document: proxy_association.owner, ingest: proxy_association.owner.try(:ingest)}.reject {|k,v| v.blank?}.reverse_merge(chunk_attributes))
    end
  end
  has_many :tracks, through: :chunks, source: :track
  has_many :tracks_including_master_track, through: :segments, source: :track, class_name: "Track"
  has_one :master_document_segment, -> { where(is_master: true) }, foreign_key: :document_id, dependent: :destroy, class_name: "Segment::DocumentSegment"
  has_one :track, through: :master_document_segment, class_name: "Track::DocumentTrack"
  accepts_nested_attributes_for :track, allow_destroy: true
  acts_as_ordered_taggable_on :tags, :auto

  validates :slug, presence: true, uniqueness: {case_sensitive: false}
  validates :title, presence: true, length: {maximum: 255}, if: :is_root?

  # public scopes
  filtered_scopes :sort_order, :reverse_sort, :is_root, :any_of_locales,
    :duration_lt, :duration_gt, :duration_lteq, :duration_gteq
  scope :sort_order, lambda {|param|
    case param.first[0]  # E.g. get first key of {"id"=>"asc"}
    when "id"
      order(self.arel_table[:id].send(param.first[1].to_sym).to_sql)
    when "title"
      order(self.arel_table[:title].send(param.first[1].to_sym).to_sql)
    when "created_at"
      order(self.arel_table[:created_at].send(param.first[1].to_sym).to_sql)
    else
      raise ArgumentError, "Ignored unrecognized value 'sort_order[]=#{param}'."
    end
  }
  scope :reverse_sort, lambda {|param| all.reverse_order if Model::Helper.booleanize(param)}
  scope :is_root, -> (param) { Model::Helper.booleanize(param) ? where("documents.type IS NULL") : where("documents.type IS NOT NULL") }
  scope :any_of_locales, -> (params) {
    where("documents.locale ~* ?", "^(#{Array.wrap(params).join("|")})")
  }
  scope :duration_lt, -> (param) {joins(:track).where(Track.arel_table[:duration].lt(param))}
  scope :duration_gt, -> (param) {joins(:track).where(Track.arel_table[:duration].gt(param))}
  scope :duration_lteq, -> (param) {joins(:track).where(Track.arel_table[:duration].lteq(param))}
  scope :duration_gteq, -> (param) {joins(:track).where(Track.arel_table[:duration].gteq(param))}

  # private scopes
  scope :recent, lambda {|n = 5| order("documents.created_at DESC").limit(n)}
  scope :with_privacy, lambda {|privacy| where("privacy_mask & #{privacy_mask(privacy)} > 0") }
  scope :with_user_privacy, lambda {|user| user && user.id ? where("documents.privacy_mask & #{privacy_mask("public")} > 0 OR documents.user_id = ?", user) : with_privacy("public") }

  before_validation :generate_slug, :on => :create
  before_save :set_tag_owner

  class << self
    # E.g. random_slug_string(5) => "12345"
    def random_slug_string(len)
      chars = [('a'..'z'), ('A'..'Z'), ('0'..'9')].map {|i| i.to_a}.flatten
      String.new.tap {|s| 1.upto(len) {|i| s << chars[rand(chars.size - 1)]}} unless chars.empty?
    end

    def privacy_mask(number)
      numbers = PRIVACY_SETTINGS.map {|k,v| number.is_a?(Fixnum) ? v : k}
      index   = numbers.index(number.is_a?(Fixnum) ? number : number.to_s)
      index ? 2**index : 0
    end

    def slug_length; 7; end

    def generate_uid
      SecureRandom.uuid
    end
  end

  def master_document_segment
    super || build_master_document_segment(document: self)
  end

  def create_track(attributes = {})
    track_attributes = attributes.symbolize_keys.merge(type: track_type_class_name)
    transaction do
      if is_root?
        # Root document needs to build a segment for its own
        if master_document_segment.new_record?
          tr = master_document_segment.build_track(track_attributes)
          master_document_segment.save
          tr.reload
        else
          Track.destroy(master_document_segment.track) if master_document_segment && master_document_segment.track
          tr = Track.create(track_attributes)
          master_document_segment.update_attributes(track: tr)
          tr
        end
      else
        # Chunks always have a master segment and need to update the track
        tr = Track.create(track_attributes)
        master_chunk_segment.update_attributes(track: tr)
        tr
      end
    end
  end

  def build_track(attributes = {})
    attributes = attributes.symbolize_keys
    segment_attributes = attributes.select {|k, v| k == :ingest}
    track_attributes = attributes.merge({type: track_type_class_name})

    if is_root?
      # Root document needs to build a segment for its own
      segment_attributes.merge!({document: self})
      build_master_document_segment(segment_attributes).build_track(track_attributes)
    else
      # Chunks need to update their master segment
      segment_attributes.merge!({chunk: self})
      master_segment.attributes = segment_attributes
      master_segment.build_track(track_attributes)
    end
  end

  def privacy=(values)
    self.privacy_mask = ([values].flatten.map(&:to_s) & PRIVACY_SETTINGS.keys).sum {|d| self.class.privacy_mask(d)}
  end

  def privacy
    PRIVACY_SETTINGS.keys.reject {|d| ((privacy_mask || 0) & self.class.privacy_mask(d)).zero?}
  end

  def privacy_private?
    privacy.include?("private")
  end

  def privacy_public?
    privacy.include?("public")
  end

  def privacy_unlisted?
    privacy.include?("unlisted")
  end

  def transcribed?
    !!ingests.order(id: :desc).first.try(:finished?)
  end

  def is_root?
    self.type == nil
  end
  alias_method :is_root, :is_root?

  def master_segment
    master_document_segment
  end

  # Overrides attribute
  def rich_text
    # result = chunks.best.rich_text
    chunks.rich_text
  end

  protected

  def generate_slug
    begin; self.slug = self.class.random_slug_string(self.class.slug_length); end while self.class.where(:slug => slug).present?
  end

  def set_tag_owner
    # Set the owner of some tags based on the current tag_list
    set_owner_tag_list_on(user, :tags, self.tag_list) if changes[:tag_list]
  end

  def track_type_class_name
    self.class.name == "Document" ? Track::DocumentTrack.name : Track::ChunkTrack.name
  end

  # Called from association on @record.chunks << @chunk or @record.chunk_ids = [1]
  # Copy document, ingest, track
  def after_add_child_segment(segment)
    segment.document ||= self.document if new_record?
  end
end
