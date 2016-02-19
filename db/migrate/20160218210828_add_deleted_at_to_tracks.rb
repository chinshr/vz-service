class AddDeletedAtToTracks < ActiveRecord::Migration
  def change
    add_column :tracks, :deleted_at, :datetime
    add_index :tracks, :deleted_at
  end
end
