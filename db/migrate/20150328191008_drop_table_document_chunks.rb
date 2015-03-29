class DropTableDocumentChunks < ActiveRecord::Migration
  def up
    drop_table "document_chunks"
  end

  def down
    create_table "document_chunks", force: true do |t|
      t.integer  "document_id"
      t.integer  "offset",                                                 null: false
      t.decimal  "duration",          precision: 11, scale: 5
      t.decimal  "start_time",        precision: 11, scale: 5
      t.decimal  "end_time",          precision: 11, scale: 5
      t.text     "response"
      t.string   "text"
      t.float    "score"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "position"
      t.string   "type"
      t.integer  "processing_status",                          default: 0, null: false
      t.text     "processing_errors"
    end

    add_index "document_chunks", ["document_id"], name: "index_document_chunks_on_document_id", using: :btree
    add_index "document_chunks", ["offset"], name: "index_document_chunks_on_offset", using: :btree
    add_index "document_chunks", ["position"], name: "index_document_chunks_on_position", using: :btree
    add_index "document_chunks", ["processing_status"], name: "index_document_chunks_on_processing_status", using: :btree
    add_index "document_chunks", ["score"], name: "index_document_chunks_on_score", using: :btree
    add_index "document_chunks", ["type"], name: "index_document_chunks_on_type", using: :btree
  end
end
