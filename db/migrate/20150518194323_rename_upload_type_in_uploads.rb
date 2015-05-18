class RenameUploadTypeInUploads < ActiveRecord::Migration
  UPLOAD_NAMES = ['Upload::Audio']

  def up
    UPLOAD_NAMES.each do |upload_name|
      execute "UPDATE uploads SET type = '#{upload_name}Upload' WHERE uploads.type = '#{upload_name}'"
    end
  end

  def down
    UPLOAD_NAMES.each do |upload_name|
      execute "UPDATE uploads SET type = '#{upload_name}' WHERE uploads.type = '#{upload_name}Upload'"
    end
  end
end
