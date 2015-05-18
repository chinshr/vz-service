class RenameIngestTypeInIngests < ActiveRecord::Migration
  INGEST_NAMES = ['Ingest::Audio']

  def up
    INGEST_NAMES.each do |ingest_name|
      execute "UPDATE ingests SET type = '#{ingest_name}Ingest' WHERE ingests.type = '#{ingest_name}'"
    end
  end

  def down
    INGEST_NAMES.each do |ingest_name|
      execute "UPDATE ingests SET type = '#{ingest_name}' WHERE ingests.type = '#{ingest_name}Ingest'"
    end
  end
end
