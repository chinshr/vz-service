class AddChunkIdPositionToSegments < ActiveRecord::Migration
  def change
    add_column :segments, :chunk_id, :integer
    add_column :segments, :position, :integer
    add_index :segments, :chunk_id
    add_index :segments, :position
  end
end
