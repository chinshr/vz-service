class DropTableIngestAudioSegments < ActiveRecord::Migration
  def up
    drop_table :ingest_audio_segments
  end
  
  def down
    create_table "ingest_audio_segments", force: true do |t|
      t.integer  "ingest_id"
      t.integer  "offset"
      t.decimal  "duration",   precision: 9, scale: 3
      t.decimal  "start_time", precision: 9, scale: 3
      t.decimal  "end_time",   precision: 9, scale: 3
      t.text     "response"
      t.string   "best_text"
      t.float    "best_score"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
  end
end
