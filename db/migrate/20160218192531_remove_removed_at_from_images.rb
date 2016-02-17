class RemoveRemovedAtFromImages < ActiveRecord::Migration
  def up
    remove_column :images, :removed_at
  end

  def down
    add_column :images, :removed_at, :datetime
    add_index :images, :removed_at
  end
end
