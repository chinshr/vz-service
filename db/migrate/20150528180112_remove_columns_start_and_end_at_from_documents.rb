class RemoveColumnsStartAndEndAtFromDocuments < ActiveRecord::Migration
  def up
    remove_column :documents, :start_at
    remove_column :documents, :end_at
  end

  def down
    add_column :documents, :start_at, :datetime
    add_column :documents, :end_at, :datetime
    add_index :documents, :start_at
    add_index :documents, :end_at
  end
end
