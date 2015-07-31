class AddColumnsStartAndEndTimeToDocuments < ActiveRecord::Migration
  def change
    add_column :documents, :start_time, :decimal, precision: 15, scale: 3
    add_column :documents, :end_time, :decimal, precision: 15, scale: 3
  end
end
