class AddAasmStateToIngestServers < ActiveRecord::Migration
  def change
    add_column :ingest_servers, :aasm_state, :string, default: 'pending', null: false
    add_column :ingest_servers, :enabled_at, :datetime
    add_column :ingest_servers, :disabled_at, :datetime

    add_index :ingest_servers, :aasm_state
  end
end
