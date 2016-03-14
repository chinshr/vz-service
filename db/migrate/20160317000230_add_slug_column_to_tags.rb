class AddSlugColumnToTags < ActiveRecord::Migration
  def change
    add_column :tags, :slug, :string
    add_index :tags, :slug

    add_column :tags, :featured, :boolean, null: false, default: false
    add_index :tags, :featured
  end
end
