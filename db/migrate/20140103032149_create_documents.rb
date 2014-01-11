class CreateDocuments < ActiveRecord::Migration
  def change
    create_table :documents do |t|
      t.string :title
      t.string :slug, null: false
      t.text :description
      t.integer :privacy_mask, default: 0, null: false
      t.string :locale, limit: 5, default: "en-US", null: false
      t.timestamps
    end
    
    add_index :documents, :title
    add_index :documents, :slug, unique: true
    add_index :documents, :privacy_mask
    add_index :documents, :locale
    add_index :documents, :created_at
    add_index :documents, :updated_at
  end
end
