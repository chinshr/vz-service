class AddColumnIngestIterationToTracks < ActiveRecord::Migration
  def change
    add_column :tracks, :ingest_iteration, :integer
    add_index :tracks, :ingest_iteration
  end
end
