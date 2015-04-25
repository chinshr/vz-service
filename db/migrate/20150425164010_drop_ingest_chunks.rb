class DropIngestChunks < ActiveRecord::Migration
  def up
    drop_table :ingest_chunks
  end

  def down
    create_table "ingest_chunks", force: true do |t|
      t.integer  "ingest_id"
      t.decimal  "offset",            precision: 11, scale: 5,             null: false
      t.decimal  "duration",          precision: 11, scale: 5
      t.decimal  "start_time",        precision: 11, scale: 5
      t.decimal  "end_time",          precision: 11, scale: 5
      t.string   "text"
      t.float    "score"
      t.integer  "position"
      t.string   "type"
      t.integer  "processing_status",                          default: 0, null: false
      t.json     "response"
      t.json     "processing_errors"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "ingest_chunks", ["ingest_id"], name: "index_ingest_chunks_on_ingest_id", using: :btree
    add_index "ingest_chunks", ["offset"], name: "index_ingest_chunks_on_offset", using: :btree
    add_index "ingest_chunks", ["position"], name: "index_ingest_chunks_on_position", using: :btree
    add_index "ingest_chunks", ["processing_status"], name: "index_ingest_chunks_on_processing_status", using: :btree
    add_index "ingest_chunks", ["score"], name: "index_ingest_chunks_on_score", using: :btree
    add_index "ingest_chunks", ["type"], name: "index_ingest_chunks_on_type", using: :btree
  end
end
