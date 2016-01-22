class RemoveFileAndS3ColumnsFromUploads < ActiveRecord::Migration
  def up
    remove_column :uploads, :file_name
    remove_column :uploads, :file_type
    remove_column :uploads, :file_size
    remove_column :uploads, :s3_url
  end

  def down
    add_column :uploads, :file_name, :string
    add_column :uploads, :file_type, :string
    add_column :uploads, :file_size, :integer
    add_column :uploads, :s3_url, :string
  end
end
