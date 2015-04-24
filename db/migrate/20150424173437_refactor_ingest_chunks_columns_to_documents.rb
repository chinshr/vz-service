class RefactorIngestChunksColumnsToDocuments < ActiveRecord::Migration
  def up
    add_column :documents, :ingest_id, :integer
    add_column :documents, :offset, :decimal, precision: 11, scale: 5 #, null: false
    add_column :documents, :duration, :decimal, precision: 11, scale: 5
    add_column :documents, :start_time, :decimal, precision: 11, scale: 5
    add_column :documents, :end_time, :decimal, precision: 11, scale: 5
    add_column :documents, :score, :float
    add_column :documents, :position, :integer
    add_column :documents, :type, :string
    add_column :documents, :processing_status, :integer, default: 0, null: false
    add_column :documents, :response, :json
    add_column :documents, :processing_errors, :json

    add_index :documents, :ingest_id
    add_index :documents, :offset
    add_index :documents, :position
    add_index :documents, :processing_status
    add_index :documents, :score
    add_index :documents, :type
  end

  def down
    remove_column :documents, :ingest_id
    remove_column :documents, :offset
    remove_column :documents, :duration
    remove_column :documents, :start_time
    remove_column :documents, :end_time
    remove_column :documents, :score
    remove_column :documents, :position
    remove_column :documents, :type
    remove_column :documents, :processing_status
    remove_column :documents, :response
    remove_column :documents, :processing_errors
  end
end
