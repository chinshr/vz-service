class CreateIngestAudioSegments < ActiveRecord::Migration
  def change
    create_table :ingest_audio_segments do |t|
      t.integer :ingest_id
      t.integer :offset
      t.decimal :duration, precision: 9, scale: 3
      t.decimal :start_time, precision: 9, scale: 3
      t.decimal :end_time, precision: 9, scale: 3
      t.text :response
      t.string :best_text
      t.float :best_score
      t.timestamps
    end
    add_index :ingest_audio_segments, :ingest_id
    add_index :ingest_audio_segments, :offset
  end
end
