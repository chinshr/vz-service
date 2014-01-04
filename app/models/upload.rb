class Upload < ActiveRecord::Base
  has_one :ingest
  
  validates :file_name, presence: true, length: { maximum: 255 }
  validates :file_type, presence: true, length: { maximum: 255 }
  validates :s3_url, presence: true, length: { maximum: 255 }
end
