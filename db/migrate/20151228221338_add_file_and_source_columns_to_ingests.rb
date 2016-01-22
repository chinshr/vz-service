class AddFileAndSourceColumnsToIngests < ActiveRecord::Migration
  def up
    add_column :ingests, :file_name, :string
    add_column :ingests, :file_type, :string
    add_column :ingests, :file_size, :integer, limit: 8 # bigint
    add_column :ingests, :source_url, :string
    add_index :ingests, :file_type

    execute "UPDATE ingests SET file_name = uploads.file_name FROM uploads WHERE ingests.upload_id = uploads.id"
    execute "UPDATE ingests SET file_type = uploads.file_type FROM uploads WHERE ingests.upload_id = uploads.id"
    execute "UPDATE ingests SET file_size = uploads.file_size FROM uploads WHERE ingests.upload_id = uploads.id"
    execute "UPDATE ingests SET source_url = uploads.s3_url FROM uploads WHERE ingests.upload_id = uploads.id"
  end

  def down
    execute "UPDATE uploads SET file_name = ingests.file_name FROM ingests WHERE ingests.upload_id = uploads.id"
    execute "UPDATE uploads SET file_type = ingests.file_type FROM ingests WHERE ingests.upload_id = uploads.id"
    execute "UPDATE uploads SET file_size = ingests.file_size FROM ingests WHERE ingests.upload_id = uploads.id"
    execute "UPDATE uploads SET s3_url = ingests.source_url FROM ingests WHERE ingests.upload_id = uploads.id"

    remove_index :ingests, :file_type
    remove_column :ingests, :file_name
    remove_column :ingests, :file_type
    remove_column :ingests, :file_size
    remove_column :ingests, :source_url
  end
end
