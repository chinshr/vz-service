class CreateImages < ActiveRecord::Migration
  def change
    create_table :images do |t|
      t.string :uid
      t.text :path
      t.integer :image_format_id
      t.integer :size
      t.integer :ingest_id
      t.integer :iteration, null: false, default: 0
      t.datetime :removed_at
      t.timestamps
    end
    add_index :images, :uid
    add_index :images, :image_format_id
    add_index :images, :ingest_id
    add_index :images, :iteration
    add_index :images, :removed_at
  end
end
