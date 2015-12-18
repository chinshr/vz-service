class UpdateMediaIngestFromIngests < ActiveRecord::Migration
  def up
    execute "UPDATE ingests SET type = 'Ingest::MediaIngest'"
  end

  def down
    execute "UPDATE ingests SET type = 'Ingest::AudioIngest' WHERE ingests.file_type ~ '^(audio)\/?.*$'"
    execute "UPDATE ingests SET type = 'Ingest::VideoIngest' WHERE ingests.file_type ~ '^(video)\/?.*$'"
  end
end
