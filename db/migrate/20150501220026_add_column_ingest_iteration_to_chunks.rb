class AddColumnIngestIterationToChunks < ActiveRecord::Migration
  def change
    add_column :documents, :ingest_iteration, :integer
    add_index :documents, :ingest_iteration
  end
end
