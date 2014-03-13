class AddTrackIdToIngests < ActiveRecord::Migration
  def change
    add_column :ingests, :track_id, :integer
    add_index :ingests, :track_id
  end
end
