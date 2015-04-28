class AddDocumentIdToDocuments < ActiveRecord::Migration
  def change
    add_column :documents, :document_id, :integer
    add_index :documents, :document_id
  end
end
