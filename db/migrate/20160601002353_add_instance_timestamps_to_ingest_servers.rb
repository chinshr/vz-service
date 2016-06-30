class AddInstanceTimestampsToIngestServers < ActiveRecord::Migration
  def change
    add_column :ingest_servers, :stopped_at, :datetime
    add_column :ingest_servers, :terminated_at, :datetime
    add_index :ingest_servers, :stopped_at
    add_index :ingest_servers, :terminated_at
  end
end
