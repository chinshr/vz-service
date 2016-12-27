class AddProcessedStagesMaskToDocuments < ActiveRecord::Migration
  def change
    add_column :documents, :processed_stages_mask, :integer, null: false, default: 0
    add_index :documents, :processed_stages_mask
  end
end
