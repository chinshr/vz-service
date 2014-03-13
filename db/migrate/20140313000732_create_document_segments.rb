class CreateDocumentSegments < ActiveRecord::Migration
  def change
    create_table :document_segments do |t|
      t.integer  :document_id
      t.integer  :offset, null: false
      t.decimal  :duration,   precision: 11, scale: 5
      t.decimal  :start_time, precision: 11, scale: 5
      t.decimal  :end_time,   precision: 11, scale: 5
      t.text     :response
      t.string   :text
      t.float    :score

      t.timestamps
    end
    add_index :document_segments, :document_id
    add_index :document_segments, :offset
  end
end
