class Document < ActiveRecord::Base
  SLUG_LENGTH = 6
  PRIVACY_SETTINGS = {:public => 0, :private => 1, :unlisted => 2}
  
  has_many :ingests, as: :ingestable

  validates :slug, presence: true, uniqueness: {case_sensitive: false}
  validates :title, presence: true, length: { maximum: 255 }
  
  before_validation :generate_slug
  
  class << self
    
    def privacy_mask(number)
      numbers = PRIVACY_SETTINGS.map {|k,v| number.is_a?(Fixnum) ? v : k}
      index = numbers.index(number.is_a?(Fixnum) ? number : number.to_sym)
      index ? 2**index : 0
    end
    
  end
  
  def privacy=(values)
    settings = PRIVACY_SETTINGS.map {|k,v| k}
    self.privacy_mask = ([values].flatten.map(&:to_sym) & settings).sum {|d| self.class.privacy_mask(d)}
  end
  
  def privacy
    PRIVACY_SETTINGS.map {|k,v| k}.reject {|d| ((privacy_mask || 0) & self.class.privacy_mask(d)).zero?}
  end
  
  def trancribed?
    ingests.all? {|i| i.finished?}
  end
  
  protected
  
  def generate_slug
    chars = [('a'..'z'), ('A'..'Z'), ('0'..'9')].map {|i| i.to_a}.flatten
    self.slug = String.new.tap {|s| 1.upto(SLUG_LENGTH) {|i| s << chars[rand(chars.size - 1)]}} unless chars.empty?
  end
end
