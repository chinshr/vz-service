class AddImageFormatAttributesToImages < ActiveRecord::Migration
  def change
    add_column :images, :width, :integer
    add_column :images, :height, :integer
    add_column :images, :format, :string
    add_column :images, :aspect_ratio, :decimal, precision: 8, scale: 3
  end
end
