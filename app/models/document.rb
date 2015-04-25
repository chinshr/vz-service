require "fuzzy_match"
require "matrix"

class Document < ActiveRecord::Base
  include Model::Filter

  PRIVACY_SETTINGS = {'public' => 0, 'private' => 1, 'unlisted' => 2}

  belongs_to :user
  belongs_to :ingest
  belongs_to :track, dependent: :destroy  # <- main track
  has_many :ingests, foreign_key: :document_id
  has_many :chunks, through: :ingests
  has_many :tracks, through: :chunks, source: :track  # <- document tracks

  acts_as_ordered_taggable_on :tags, :auto

  validates :slug, presence: true, uniqueness: {case_sensitive: false}
  validates :title, presence: true, length: {maximum: 255}, if: :canonical_document?

  # public scopes
  filtered_scopes :sort_order, :reverse_sort
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
  # private scopes
  scope :recent, lambda {|n = 5| order("documents.created_at DESC").limit(n)}
  scope :with_privacy, lambda {|privacy| where("privacy_mask & #{privacy_mask(privacy)} > 0") }
  scope :with_user_privacy, lambda {|user| user && user.id ? where("documents.privacy_mask & #{privacy_mask("public")} > 0 OR documents.user_id = ?", user) : with_privacy("public") }

  before_validation :generate_slug, :on => :create
  before_save :set_tag_owner

  class << self
    # E.g. random_string(5)
    def random_string(len)
      chars = [('a'..'z'), ('A'..'Z'), ('0'..'9')].map {|i| i.to_a}.flatten
      String.new.tap {|s| 1.upto(len) {|i| s << chars[rand(chars.size - 1)]}} unless chars.empty?
    end

    def privacy_mask(number)
      numbers = PRIVACY_SETTINGS.map {|k,v| number.is_a?(Fixnum) ? v : k}
      index   = numbers.index(number.is_a?(Fixnum) ? number : number.to_s)
      index ? 2**index : 0
    end

    def slug_length; 7; end
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

  protected

  def generate_slug
    begin; self.slug = self.class.random_string(self.class.slug_length); end while self.class.where(:slug => slug).present?
  end

  def set_tag_owner
    # Set the owner of some tags based on the current tag_list
    set_owner_tag_list_on(user, :tags, self.tag_list) if changes[:tag_list]
  end

  def canonical_document?
    true
  end
end
