class AddDeletedAtToDocuments < ActiveRecord::Migration
  def change
    add_column :documents, :deleted_at, :datetime
    add_index :documents, :deleted_at
  end
end
