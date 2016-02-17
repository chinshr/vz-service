class AddRemovedAtToDocuments < ActiveRecord::Migration
  def change
    add_column :documents, :removed_at, :datetime
    add_index :documents, :removed_at
  end
end
