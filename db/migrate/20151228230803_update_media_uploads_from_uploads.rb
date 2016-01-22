class UpdateMediaUploadsFromUploads < ActiveRecord::Migration
  def up
    execute "UPDATE uploads SET type = 'Upload::MediaUpload'"
  end

  def down
    execute "UPDATE uploads SET type = 'Upload::AudioUpload' FROM ingests WHERE ingests.upload_id = uploads.id AND ingests.file_type ~ '^(audio)\/?.*$'"
    execute "UPDATE uploads SET type = 'Upload::VideoUpload' FROM ingests WHERE ingests.upload_id = uploads.id AND ingests.file_type ~ '^(video)\/?.*$'"
  end
end
