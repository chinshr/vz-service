class RemoveUniqueIndexDocumentIdTrackIdFromSegments < ActiveRecord::Migration
  def up
    remove_index "segments", name: "index_segments_on_document_id_and_track_id"
    add_index :segments, :document_id
  end

  def down
    remove_index :segments, :document_id
    add_index "segments", ["document_id", "track_id"], unique: true
  end
end
