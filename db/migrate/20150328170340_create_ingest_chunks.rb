class CreateIngestChunks < ActiveRecord::Migration
  def change
    create_table :ingest_chunks do |t|
      t.integer  "ingest_id"
      t.decimal  "offset", null: false, precision: 11, scale: 5
      t.decimal  "duration", precision: 11, scale: 5
      t.decimal  "start_time", precision: 11, scale: 5
      t.decimal  "end_time", precision: 11, scale: 5
      t.string   "text"
      t.float    "score"
      t.integer  "position"
      t.string   "type"
      t.integer  "processing_status", default: 0, null: false
      t.json     "response"
      t.json     "processing_errors"
      t.timestamps
    end

    add_index :ingest_chunks, :ingest_id
    add_index :ingest_chunks, :offset
    add_index :ingest_chunks, :position
    add_index :ingest_chunks, :processing_status
    add_index :ingest_chunks, :score
    add_index :ingest_chunks, :type
  end
end
