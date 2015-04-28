class AddIngestIdToDocuments < ActiveRecord::Migration
  def change
    add_column :documents, :ingest_id, :integer
    add_index :documents, :ingest_id
  end
end
