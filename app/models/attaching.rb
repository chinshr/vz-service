class Attaching < ActiveRecord::Base
  belongs_to :message
  belongs_to :upload
end