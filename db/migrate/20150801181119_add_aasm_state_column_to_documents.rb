class AddAasmStateColumnToDocuments < ActiveRecord::Migration
  def change
    add_column :documents, :aasm_state, :string, null: false, default: 'unpublished'
    add_column :documents, :published_at, :datetime
    add_index :documents, :aasm_state
    add_index :documents, :published_at
  end
end
