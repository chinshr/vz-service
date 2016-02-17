class AddDeletedAtToSegments < ActiveRecord::Migration
  def change
    add_column :segments, :deleted_at, :datetime
    add_index :segments, :deleted_at
  end
end
