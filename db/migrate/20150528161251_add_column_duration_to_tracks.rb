class AddColumnDurationToTracks < ActiveRecord::Migration
  def change
    add_column :tracks, :duration, :decimal, precision: 15, scale: 3
    add_index :tracks, :duration
  end
end
