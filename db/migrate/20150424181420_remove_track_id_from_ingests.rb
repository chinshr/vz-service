class RemoveTrackIdFromIngests < ActiveRecord::Migration
  def up
    remove_column :ingests, :track_id
  end

  def down
    add_column :ingests, :track_id, :integer
    add_index :ingests, :track_id
  end
end
