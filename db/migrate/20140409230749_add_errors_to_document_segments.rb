class AddErrorsToDocumentSegments < ActiveRecord::Migration
  def change
    add_column :document_segments, :processing_errors, :text
  end
end
