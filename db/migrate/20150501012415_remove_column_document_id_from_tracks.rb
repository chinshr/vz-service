class RemoveColumnDocumentIdFromTracks < ActiveRecord::Migration
  def up
    remove_column :tracks, :document_id
  end

  def down
    add_column :tracks, :document_id, :integer
    add_index :tracks, :document_id
  end
end
