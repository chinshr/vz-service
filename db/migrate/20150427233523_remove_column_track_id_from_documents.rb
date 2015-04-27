class RemoveColumnTrackIdFromDocuments < ActiveRecord::Migration
  def up
    remove_column :documents, :track_id
  end

  def down
    add_column :documents, :track_id, :integer
    add_index :documents, :track_id
  end
end
