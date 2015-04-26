class AddUidToTracks < ActiveRecord::Migration
  def change
    add_column :tracks, :uid, :string
    add_index :tracks, :uid
  end
end
