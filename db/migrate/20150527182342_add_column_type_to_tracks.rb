class AddColumnTypeToTracks < ActiveRecord::Migration
  def change
    add_column :tracks, :type, :string
    add_index :tracks, :type
  end
end
