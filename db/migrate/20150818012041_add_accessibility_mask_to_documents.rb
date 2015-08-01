class AddAccessibilityMaskToDocuments < ActiveRecord::Migration
  def change
    add_column :documents, :accessibility_mask, :integer, default: 0, null: false
    add_index :documents, :accessibility_mask
  end
end
