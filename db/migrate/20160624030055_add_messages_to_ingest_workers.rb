class AddMessagesToIngestWorkers < ActiveRecord::Migration
  def change
    add_column :ingest_workers, :messages, :json, null: false, default: {}
  end
end
