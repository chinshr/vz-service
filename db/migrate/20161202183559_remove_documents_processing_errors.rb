class RemoveDocumentsProcessingErrors < ActiveRecord::Migration
  def up
    remove_column :documents, :processing_errors
  end

  def down
    add_column :documents, :processing_errors, :json
  end
end
