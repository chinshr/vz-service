class RemoveStartEndTimeFromDocuments < ActiveRecord::Migration
  def up
    remove_column :documents, :start_time
    remove_column :documents, :end_time
  end

  def down
    add_column :documents, :start_time, :decimal, precision: 11, scale: 5
    add_column :documents, :end_time, :decimal, precision: 11, scale: 5
  end
end
