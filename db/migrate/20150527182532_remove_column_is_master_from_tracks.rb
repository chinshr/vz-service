class RemoveColumnIsMasterFromTracks < ActiveRecord::Migration
  def up
    remove_column :tracks, :is_master
  end

  def down
    add_column :tracks, :is_master, :boolean, default: false, null: false
    add_index :tracks, :is_master
  end
end
