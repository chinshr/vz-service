class CreateImageFormats < ActiveRecord::Migration
  def change
    create_table :image_formats do |t|
      t.string :uid
      t.string :format
      t.integer :width
      t.integer :height
      t.boolean :is_source, null: false, default: false
      t.decimal :aspect_ratio, precision: 8, scale: 3
      t.timestamps
    end
    add_index :image_formats, :uid
    add_index :image_formats, :format
    add_index :image_formats, :width
    add_index :image_formats, :height
    add_index :image_formats, :aspect_ratio
  end
end
