class AddTrackIdToDocuments < ActiveRecord::Migration
  def change
    add_column :documents, :track_id, :integer
    add_index :documents, :track_id
  end
end
