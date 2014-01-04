class Document < ActiveRecord::Base
  has_many :ingests, as: :ingestable

  validates :title, presence: true, length: { maximum: 255 }
end
