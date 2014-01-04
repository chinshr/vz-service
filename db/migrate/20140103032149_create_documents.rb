class CreateDocuments < ActiveRecord::Migration
  def change
    create_table :documents do |t|
      t.string :title
      t.string :slug
      t.text :description
      t.timestamps
    end
    
    add_index :documents, :title
    add_index :documents, :slug
    add_index :documents, :created_at
    add_index :documents, :updated_at
  end
end
