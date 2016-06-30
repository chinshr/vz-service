class DropIngestProcesses < ActiveRecord::Migration
  def up
    drop_table "ingest_processes"
  end

  def down
    create_table "ingest_processes", force: :cascade do |t|
      t.integer  "ingest_id"
      t.integer  "server_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "ingest_processes", ["ingest_id", "server_id"], name: "index_ingest_processes_on_ingest_id_and_server_id", unique: true, using: :btree
    add_index "ingest_processes", ["server_id", "ingest_id"], name: "index_ingest_processes_on_server_id_and_ingest_id", unique: true, using: :btree
  end
end
