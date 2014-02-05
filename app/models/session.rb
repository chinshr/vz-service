class Session < ActiveRecord::Base
  has_many :uploads
  
  validates :uid, :uniqueness => {:case_sensitive => false}
end
