class AddProcessingStatusToDocumentSegments < ActiveRecord::Migration
  def change
    add_column :document_segments, :processing_status, :integer, default: 0, null: false
    add_index :document_segments, :processing_status
  end
end
