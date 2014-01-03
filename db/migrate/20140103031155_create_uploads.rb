class CreateUploads < ActiveRecord::Migration
  def change
    create_table :uploads do |t|
      t.string :file_name
      t.string :file_type
      t.string :file_size
      t.string :s3_url
      t.timestamps
    end
    add_index :uploads, :file_name
    add_index :uploads, :file_type
    add_index :uploads, :file_size
  end
end
