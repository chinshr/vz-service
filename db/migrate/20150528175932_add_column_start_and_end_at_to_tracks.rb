class AddColumnStartAndEndAtToTracks < ActiveRecord::Migration
  def change
    add_column :tracks, :start_at, :datetime
    add_column :tracks, :end_at, :datetime
    add_index :tracks, :start_at
    add_index :tracks, :end_at
  end
end
