class RemoveColumnIngestIdFromDocuments < ActiveRecord::Migration
  def up
    remove_column :documents, :ingest_id
  end

  def down
    add_column :documents, :ingest_id, :integer
    add_index :documents, :ingest_id
  end
end
