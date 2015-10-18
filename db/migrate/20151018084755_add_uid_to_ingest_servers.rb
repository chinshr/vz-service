class AddUidToIngestServers < ActiveRecord::Migration
  def change
    add_column :ingest_servers, :uid, :string
    add_index :ingest_servers, :uid, unique: true
  end
end
