class AddDocumentIdToDocumentIngests < ActiveRecord::Migration
  def change
    add_column :document_ingests, :document_id, :integer
    add_index :document_ingests, :document_id
  end
end
