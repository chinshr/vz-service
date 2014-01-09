class Document < ActiveRecord::Base
  SLUG_LENGTH = 6
  has_many :ingests, as: :ingestable

  validates :slug, presence: true, uniqueness: {case_sensitive: false}
  validates :title, presence: true, length: { maximum: 255 }
  
  before_validation :generate_slug
  
  protected
  
  def generate_slug
    chars = [('a'..'z'), ('A'..'Z'), ('0'..'9')].map {|i| i.to_a}.flatten
    self.slug = String.new.tap {|s| 1.upto(SLUG_LENGTH) {|i| s << chars[rand(chars.size - 1)]}} unless chars.empty?
  end
end
