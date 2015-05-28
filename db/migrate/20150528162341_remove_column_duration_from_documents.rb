class RemoveColumnDurationFromDocuments < ActiveRecord::Migration
  def up
    remove_column :documents, :duration
  end

  def down
    add_column :documents, :duration, :decimal, precision: 11, scale: 5
  end
end
