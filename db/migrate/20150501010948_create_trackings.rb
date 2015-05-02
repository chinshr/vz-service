class CreateTrackings < ActiveRecord::Migration
  def change
    create_table :trackings do |t|
      t.integer :document_id
      t.integer :track_id
      t.integer :ingest_id
    end
    add_index :trackings, [:document_id, :track_id], unique: true
    add_index :trackings, :ingest_id
    add_index :trackings, :track_id
  end
end
