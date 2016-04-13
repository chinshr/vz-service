class AddDeletedAtToIngestServers < ActiveRecord::Migration
  def change
    add_column :ingest_servers, :deleted_at, :datetime
    add_index :ingest_servers, :deleted_at
  end
end
