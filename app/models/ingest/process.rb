class Ingest::Process < ActiveRecord::Base
  self.table_name = "ingest_processes"

  belongs_to :ingest
  belongs_to :server
end