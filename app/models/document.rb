require "fuzzy_match"
require "matrix"

class Document < ActiveRecord::Base
  include Model::Filter

  SLUG_LENGTH      = 6
  PRIVACY_SETTINGS = {'public' => 0, 'private' => 1, 'unlisted' => 2}

  belongs_to :user
  has_many :ingests, as: :ingestable
  has_many :chunks, dependent: :destroy
  has_many :tracks, :through => :ingests

  acts_as_ordered_taggable_on :tags, :auto

  validates :slug, presence: true, uniqueness: {case_sensitive: false}
  validates :title, presence: true, length: {maximum: 255}

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

    def privacy_mask(number)
      numbers = PRIVACY_SETTINGS.map {|k,v| number.is_a?(Fixnum) ? v : k}
      index   = numbers.index(number.is_a?(Fixnum) ? number : number.to_s)
      index ? 2**index : 0
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

  def track
    tracks.order(id: :desc).first
  end

  def score
    chunks.average(:score)
  end

  def duration
    chunks.sum(:duration)
  end

  def update_content_from(grouped_chunks)
    self.update_attributes(html: grouped_chunks.text, rich_text: grouped_chunks.rich_text)
  end

  def normalize_chunk_scores!
    self.chunks.group_by(&:position).each do |position, grouped_chunks|
      levenshtein_array = grouped_chunks.each_index.inject([]) do |column, column_index|
        column << grouped_chunks.each_index.inject([]) do |row, row_index|
          row << if grouped_chunks[column_index].text && grouped_chunks[row_index].text
            grouped_chunks[column_index].text.levenshtein_similar(grouped_chunks[row_index].text)
          else
            0.0
          end
        end
      end

      levenshtein_matrix = Matrix.rows(levenshtein_array)
      combined_word_count = grouped_chunks.map(&:text).inject(0) {|r, e| r += e.to_s.split.size}
      eigen_array = grouped_chunks.each_index.inject([]) do |v, index|
        v << (combined_word_count.to_f > 0 ? grouped_chunks[index].text.to_s.split.size / combined_word_count.to_f : 1.0)
      end
      eigen_vector = Vector.elements(eigen_array, true)
      score_vector = levenshtein_matrix * eigen_vector

      # update chunk score
      score_vector.each_with_index do |vector_score, index|
        grouped_chunks[index].score = vector_score
        grouped_chunks[index].save if grouped_chunks[index].changed?
      end
    end
  end

  protected

  def generate_slug
    chars = [('a'..'z'), ('A'..'Z'), ('0'..'9')].map {|i| i.to_a}.flatten
    self.slug = String.new.tap {|s| 1.upto(SLUG_LENGTH) {|i| s << chars[rand(chars.size - 1)]}} unless chars.empty?
  end

  def set_tag_owner
    # Set the owner of some tags based on the current tag_list
    set_owner_tag_list_on(user, :tags, self.tag_list) if changes[:tag_list]
  end
end
