class AddTurkeeTaskIdToDocuments < ActiveRecord::Migration
  def change
    add_column :documents, :turkee_task_id, :integer
    add_index :documents, :turkee_task_id
  end
end
