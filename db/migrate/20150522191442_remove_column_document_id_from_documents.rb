class RemoveColumnDocumentIdFromDocuments < ActiveRecord::Migration
  def up
    remove_column :documents, :document_id
  end

  def down
    add_column :documents, :document_id, :integer
    add_index :documents, :document_id
  end
end
