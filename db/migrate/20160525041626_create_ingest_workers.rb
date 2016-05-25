class CreateIngestWorkers < ActiveRecord::Migration
  def change
    create_table :ingest_workers do |t|
      t.string :uid
      t.integer :ingest_id
      t.integer :ingest_iteration
      t.integer :server_id
      t.string :worker_name
      t.string :aasm_state, default: 'created', null: false
      t.datetime :started_at
      t.datetime :stopped_at
      t.datetime :finished_at
      t.timestamps null: false
    end

    add_index :ingest_workers, :uid
    add_index :ingest_workers, :ingest_id
    add_index :ingest_workers, :ingest_iteration
    add_index :ingest_workers, :server_id
    add_index :ingest_workers, :worker_name
    add_index :ingest_workers, :aasm_state
    add_index :ingest_workers, :created_at
    add_index :ingest_workers, :started_at
    add_index :ingest_workers, :stopped_at
    add_index :ingest_workers, :finished_at
  end
end
