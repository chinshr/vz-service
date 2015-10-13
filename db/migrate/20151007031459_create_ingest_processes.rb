class CreateIngestProcesses < ActiveRecord::Migration
  def change
    create_table :ingest_processes do |t|
      t.integer :ingest_id
      t.integer :server_id
      t.timestamps
    end
    add_index :ingest_processes, [:ingest_id, :server_id], unique: true
    add_index :ingest_processes, [:server_id, :ingest_id], unique: true
  end
end
