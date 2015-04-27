class AddDocumentIdAndIsMasterToTracks < ActiveRecord::Migration
  def change
    add_column :tracks, :document_id, :integer
    add_index :tracks, :document_id

    add_column :tracks, :is_master, :boolean, null: false, default: false
    add_index :tracks, :is_master
  end
end
