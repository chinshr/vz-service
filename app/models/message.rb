class Message < ActiveRecord::Base
  include ::Model::Uid
  
  validates :from, presence: true
  validates :to, presence: true
end
