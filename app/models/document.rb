require "fuzzy_match"
require "matrix"

class Document < ActiveRecord::Base
  extend FriendlyId
  include AASM
  include Model::AASM::Support
  include Model::Filter
  include Model::Uid
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::SanitizeHelper

  PRIVACY_SETTINGS       = {'public' => 0, 'private' => 1, 'unlisted' => 2}
  ACCESSIBILITY_SETTINGS = {'view' => 0, 'comment' => 1, 'edit' => 2}
  STATE_UNPUBLISHED      = 0
  STATE_PUBLISHED        = 1
  STATE_REMOVED          = 2
  STATES                 = {unpublished: STATE_UNPUBLISHED, published: STATE_PUBLISHED, removed: STATE_REMOVED}

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

  has_many :images, :through => :image_ingests, :source => :images
  has_many :image_ingests, :as => :ingestable,
    :class_name => "Ingest::ImageIngest", dependent: :destroy

  friendly_id :title_and_slug_id, use: [:slugged, :history]
  acts_as_ordered_taggable_on :tags, :auto
  has_paper_trail :only => [:title, :description, :text, :html, :rich_text,
    :offset, :score]
  acts_as_paranoid

  validates :slug_id, presence: true, uniqueness: {case_sensitive: false}
  validates :title, presence: true, length: {maximum: 255}, if: :is_root?

  # public scopes
  filtered_scopes :sort_order, :reverse_sort, :user_id, :is_root, :any_of_locales,
    :duration_lt, :duration_gt, :duration_lteq, :duration_gteq,
    :any_of_status, :none_of_status, :any_of_tags, :none_of_tags,
    :created_at_gt, :created_at_gteq, :created_at_lt, :created_at_lteq,
    :updated_at_gt, :updated_at_gteq, :updated_at_lt, :updated_at_lteq,
    :published_at_gt, :published_at_gteq, :published_at_lt, :published_at_lteq

  scope :sort_order, -> (param) {
    case param.first[0]  # E.g. get first key of {"id"=>"asc"}
    when "id"
      order(self.arel_table[:id].send(param.first[1].to_sym).to_sql)
    when "title"
      order(self.arel_table[:title].send(param.first[1].to_sym).to_sql)
    when "created_at"
      order(self.arel_table[:created_at].send(param.first[1].to_sym).to_sql)
    when "published_at"
      order(self.arel_table[:published_at].send(param.first[1].to_sym).to_sql)
    else
      raise ArgumentError, "Ignored unrecognized value 'sort_order[]=#{param}'."
    end
  }
  scope :reverse_sort, -> (param) { all.reverse_order if Model::Helper.booleanize(param) }
  scope :user_id, -> (id) { joins(:user).where("documents.user_id = users.id AND (users.uid = ? OR users.id = ?)", id.to_s, id.to_i.to_s == id.to_s ? id.to_i : nil) }
  scope :is_root, -> (param = true) { Model::Helper.booleanize(param) ? where("documents.type IS NULL") : where("documents.type IS NOT NULL") }
  scope :any_of_locales, -> (params) {
    where("documents.locale ~* ?", "^(#{Array.wrap(params).join("|")})")
  }
  scope :duration_lt, -> (param) {joins(:track).where(Track.arel_table[:duration].lt(param))}
  scope :duration_gt, -> (param) {joins(:track).where(Track.arel_table[:duration].gt(param))}
  scope :duration_lteq, -> (param) {joins(:track).where(Track.arel_table[:duration].lteq(param))}
  scope :duration_gteq, -> (param) {joins(:track).where(Track.arel_table[:duration].gteq(param))}
  scope :any_of_status, -> (params) {where("documents.aasm_state IN (?)", [params].flatten.map(&:to_s).
    map {|s| s.match(/^([\-]{,1}[0-9]+)$/) ? s : nil}.reject(&:blank?).map {|s| Document::STATES.key(s.to_i)}.uniq)}
  scope :none_of_status, -> (params) {where("documents.aasm_state NOT IN (?)", [params].flatten.map(&:to_s).
    map {|s| s.match(/^([\-]{,1}[0-9]+)$/) ? s : nil}.reject(&:blank?).map {|s| Document::STATES.key(s.to_i)}.uniq)}
  scope :any_of_tags, -> (params) {
    tagged_with(params, on: :tags, any: true)
  }
  scope :none_of_tags, -> (params) {
    tagged_with(params, on: :tags, exclude: true)
  }
  scope :created_at_gt, -> (date) { where(self.arel_table[:created_at].gt(Model::Helper.date_parse(date))) }
  scope :created_at_gteq, -> (date) { where(self.arel_table[:created_at].gteq(Model::Helper.date_parse(date))) }
  scope :created_at_lt, -> (date) { where(self.arel_table[:created_at].lt(Model::Helper.date_parse(date))) }
  scope :created_at_lteq, -> (date) { where(self.arel_table[:created_at].lteq(Model::Helper.date_parse(date))) }
  scope :updated_at_gt, -> (date) { where(self.arel_table[:updated_at].gt(Model::Helper.date_parse(date))) }
  scope :updated_at_gteq, -> (date) { where(self.arel_table[:updated_at].gteq(Model::Helper.date_parse(date))) }
  scope :updated_at_lt, -> (date) { where(self.arel_table[:updated_at].lt(Model::Helper.date_parse(date))) }
  scope :updated_at_lteq, -> (date) { where(self.arel_table[:updated_at].lteq(Model::Helper.date_parse(date))) }
  scope :published_at_gt, -> (date) { where(self.arel_table[:published_at].gt(Model::Helper.date_parse(date))) }
  scope :published_at_gteq, -> (date) { where(self.arel_table[:published_at].gteq(Model::Helper.date_parse(date))) }
  scope :published_at_lt, -> (date) { where(self.arel_table[:published_at].lt(Model::Helper.date_parse(date))) }
  scope :published_at_lteq, -> (date) { where(self.arel_table[:published_at].lteq(Model::Helper.date_parse(date))) }
  # private scopes
  scope :recent, -> (n = 5) { order("documents.created_at DESC").limit(n) }
  scope :with_privacy, -> (privacy) { where(privacy_sql_condition(privacy)) }
  scope :with_accessibility, -> (access) { where(accessibility_sql_condition(access)) }
  scope :viewable_by_user, -> (user) {
    if user && user.id
      privacy_sql       = privacy_sql_condition('public', 'unlisted')
      accessibility_sql = accessibility_sql_condition('view', 'comment', 'edit')
      where("(#{privacy_sql} AND #{accessibility_sql}) OR documents.user_id = ?", user)
    else
      accessibility_sql = accessibility_sql_condition('view', 'comment', 'edit')
      where("#{accessibility_sql} OR (documents.aasm_state = ? AND (NOT #{privacy_sql_condition('private')}))", 'published')
    end
  }
  scope :params_id, -> (params) {
    param_document_id = if params[:id].present? && params[:id].to_i.to_s == params[:id]
      params[:id]
    end
    where("documents.slug = ? OR documents.slug_id = ? OR documents.uid = ? OR documents.id = ?", params[:id], params[:id], params[:id], param_document_id)
  }
  scope :eager_load_associations, -> { eager_load([:track, {:images => :image_format}]) }

  aasm column: 'aasm_state' do
    state :unpublished, initial: true
    state :published, :enter => :enter_published
    state :removed, :enter => :enter_removed

    event :publish do
      transitions :from => [:unpublished, :published], :to => :published, :guard => :can_be_published?
    end

    event :unpublish do
      transitions :from => [:published, :unpublished], :to => :unpublished
    end

    event :remove do
      transitions :from => [:unpublished, :published, :removed], :to => :removed
    end
  end

  before_validation :set_default_privacy, :on => :create
  before_save :set_tag_owner
  after_save :update_chunks_from_segments
  after_destroy :remove_ingests

  class << self

    # E.g. random_slug_string(5) => "12345"
    def random_slug_string(len)
      chars = [('a'..'z'), ('0'..'9')].map {|i| i.to_a}.flatten
      String.new.tap {|s| 1.upto(len) {|i| s << chars[rand(chars.size - 1)]}} unless chars.empty?
    end

    def privacy_mask(number)
      numbers = PRIVACY_SETTINGS.map {|k,v| number.is_a?(Fixnum) ? v : k}
      index   = numbers.index(number.is_a?(Fixnum) ? number : number.to_s)
      index ? 2**index : 0
    end

    def privacy_sql_condition(*args)
      result = []
      Array.wrap(args).flatten.each do |privacy|
        result << "(documents.privacy_mask & #{privacy_mask(privacy)} > 0)"
      end
      result.length > 0 ? "(#{ result.join(" OR ") })" : "(1 = 1)"
    end

    def accessibility_mask(number)
      numbers = ACCESSIBILITY_SETTINGS.map {|k,v| number.is_a?(Fixnum) ? v : k}
      index   = numbers.index(number.is_a?(Fixnum) ? number : number.to_s)
      index ? 2**index : 0
    end

    def accessibility_sql_condition(*args)
      result = []
      Array.wrap(args).flatten.each do |accessibility|
        result << "(documents.accessibility_mask & #{accessibility_mask(accessibility)} > 0)"
      end
      result.length > 0 ? "(#{ result.join(" OR ") })" : "(1 = 1)"
    end

    def slug_id_length; 12; end

    def generate_uid
      SecureRandom.uuid
    end

    # "c4ea2bad-6f84-4b6c-869b-8ddcd4128d83+t..." -> 'c4ea2bad-6f84-4b6c-869b-8ddcd4128d83'
    def parse_segment_uid(segment)
      um = segment.to_s.match(/^([a-z,0-9,-]*)(?![a-z,0-9,-])/)
      um.try(:[], 1).present? ? um[1] : nil;
    end

    # "...+t1_45-3_52..." -> [1.45, 3.52]
    def parse_segment_time(segment)
      tm = segment.to_s.match(/\+t([0-9_]*)-([0-9_]*)/)
      tm = tm.try(:to_a).try(:slice, 1, 2)
      tm.try(:present?) ? tm.map {|t| t.gsub('_', '.')}.map(&:to_f) : nil
    end

    # "...+p12345678..." -> '12345678'
    def parse_segment_profile(segment)
      pm = segment.to_s.match(/\+p(.+?(?=(\+|$)))/)
      pm.try(:[], 1)
    end

    # "...#afafaf..." -> 'afafaf'
    def parse_segment_color(segment)
      cm = segment.to_s.match(/\+c(.+?(?=(\+|$)))/)
      cm.try(:[], 1)
    end

    # "...%0_75..." -> 0.75
    def parse_segment_score(segment)
      sc = segment.to_s.match(/\+s([0-9_]+?(?=(\+|$)))/)
      sc = sc.try(:[], 1)
      sc ? sc.gsub('_', '.').to_f : nil
    end
  end  # class

  def best_chunks
    chunk_ids = chunks.pluck(:id)
    Chunk.where("documents.id IN (?)", chunk_ids).
      joins("INNER JOIN segments ys ON ys.chunk_id = documents.id AND ys.type IN ('Segment::ChunkSegment')").
      joins(self.class.send(:sanitize_sql, ["INNER JOIN (SELECT ps.position AS position, MAX(score) AS max_score FROM documents p INNER JOIN segments ps ON ps.chunk_id = p.id AND ps.document_id = #{self.id} AND ps.type IN ('Segment::ChunkSegment') WHERE p.id IN (?) GROUP BY ps.position) y ON y.position = ys.position AND y.max_score = documents.score", chunk_ids])).
      order("ys.position")
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
    values = ([values].flatten.map(&:to_s) & PRIVACY_SETTINGS.keys)
    self.unpublish if values.include?('private')
    self.privacy_mask = values.sum {|d| self.class.privacy_mask(d)}
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

  def accessibility=(values)
    self.accessibility_mask = ([values].flatten.map(&:to_s) & ACCESSIBILITY_SETTINGS.keys).sum {|d| self.class.accessibility_mask(d)}
  end

  def accessibility
    ACCESSIBILITY_SETTINGS.keys.reject {|d| ((accessibility_mask || 0) & self.class.accessibility_mask(d)).zero?}
  end

  def accessibility_viewable?
    accessibility.include?("view") || accessibility.include?("comment") || accessibility.include?("edit")
  end

  def accessibility_commentable?
    accessibility.include?("comment") || accessibility.include?("edit")
  end

  def accessibility_editable?
    accessibility.include?("edit")
  end

  def transcribed?
    !!ingests.order(id: :desc).first.try(:finished?)
  end

  def is_root?
    self.type == nil
  end
  alias_method :is_root, :is_root?

  def master_segment; master_document_segment; end

  def rich_text
    self[:rich_text] || best_chunks.rich_text
  end

  def rich_text=(value)
    self[:rich_text] = @rich_text = value if value
  end

  def published_path
    "/@#{user.username}/#{slug}" if published?
  end

  # override
  def score
    chunks.average(:score)
  end

  def meta_title
    @meta_title ||= begin
      default = "#{title.titleize}"
      truncate(default, length: 200, separator: ' ', omission: '.')
    end
  end

  def meta_description
    @meta_description ||= begin
      default = !self[:description].blank? ? self[:description] : strip_tags(html)
      default = default.gsub("&nbsp;", " ") if default
      default = default.gsub("&amp;", " ") if default
      default = default.humanize if default
      truncate(default, length: 200, separator: ' ', omission: '...') if default
    end
  end

  def meta_keywords
    @meta_keywords ||= begin
      tag_list.map(&:downcase).join(",")
    end
  end

  def canonical_url(options = {})
    if privacy_private?
      Rails.application.routes.url_helpers.web_document_url(slug_id, options)
    elsif !privacy_private? && published? && slug.present? && user.slug.present?
      Rails.application.routes.url_helpers.web_profile_document_url("@#{user.slug}", slug, options)
    end
  end

  def published_url(options = {})
    if !privacy_private? && published? && slug.present? && user.slug.present?
      Rails.application.routes.url_helpers.web_profile_document_url("@#{user.slug}", slug, options)
    end
  end

  protected

  def set_slug_with_slug_id(normalized_slug = nil)
    generate_slug_id if new_record? && !slug_id
    set_slug_without_slug_id(normalized_slug)
  end
  alias_method_chain :set_slug, :slug_id

  def should_generate_new_friendly_id?
    new_record? || slug.blank? || recently_published? #&& !!changes[:title]
  end

  def title_and_slug_id
    title.present? && published? ? "#{title}-#{slug_id}" : slug_id
  end

  def generate_slug_id
    begin
      self.slug_id = self.class.random_slug_string(self.class.slug_id_length)
    end while self.class.where(:slug_id => slug_id).present?
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

  def update_chunks_from_segments
    update_chunks_from(@rich_text) if @rich_text && changes[:rich_text]
    @rich_text = nil
  end

  def update_chunks_from(rich_text)
    result = {}
    if segments = rich_text.is_a?(Array) ? rich_text : rich_text.try(:[], 'ops')
      # filter by chunk id, building: {'xyz': {text: ['the', 'fox'], time: [1.52, 3.61]}}
      segments.each do |segment|
        id = segment.try(:[], 'attributes').try(:[], 'segment')
        if uid = self.class.parse_segment_uid(id)
          if result[uid]
            result[uid]['text'] += [segment['insert']] if result[uid]['insert']
          else
            result[uid] ||= {}
            result[uid]['text'] = [segment['insert']]
            result[uid]['time'] = self.class.parse_segment_time(id)
          end
        end
      end
      # now, update those chunks that have changed and
      # increase the score with difference score factor
      result.keys.each do |uid|
        text = (result[uid]['text'] || []).join.gsub(/\n|\r/, '')
        time = result[uid]['time'] || []

        chunks.where(uid: uid).each do |chunk|
          similarity = chunk.text.to_s.levenshtein_similar(text)
          # update text only if different
          chunk.text = text if similarity < 1.0
          # recalculate score
          df = 1 + (1 - similarity)
          if chunk.score
            new_score   = [chunk.score * df, 1.0].min
            chunk.score = new_score if new_score > chunk.score
          end
          # adjust offset/duration using time
          chunk.start_time = time[0] if time[0] && chunk.start_time != time[0]
          chunk.end_time   = time[1] if time[1] && chunk.end_time != time[1]
          # dr = time[1] - time[0] if time[0] && time[1]
          # chunk.track.duration = dr if dr && dr != chunk.track.duration
          chunk.save if chunk.changed? # || chunk.track.changed?
        end
      end
    end
    result
  end

  def enter_published
    self.published_at = @recently_published = Time.zone.now
  end

  def recently_published?
    !!@recently_published
  end

  def can_be_published?
    !privacy_private?
  end

  def enter_removed
    self.removed_at = Time.zone.now
  end

  private

  def set_default_privacy
    self.privacy = :private if privacy.empty?
  end

  def remove_ingests
    ingests.each do |ingest|
      ingest.remove! if ingest.may_remove?
    end if is_root?
  end
end
