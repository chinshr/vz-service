class RemoveColumnPositionFromDocumentChunks < ActiveRecord::Migration
  def up
    remove_column :documents, :position
  end

  def down
    add_column :documents, :position, :integer
    add_index :documents, :position
  end
end
