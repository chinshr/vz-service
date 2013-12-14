class CreateDocumentIngests < ActiveRecord::Migration
  def change
    create_table :document_ingests do |t|
      t.string :file_name
      t.string :name
      t.string :locale, :limit => 5, :default => "en-US", :null => false
      t.integer :privacy_mask,  :default => 0, :null => false
      t.timestamps
    end
    add_index :document_ingests, :file_name
    add_index :document_ingests, :name
    add_index :document_ingests, :locale
  end
end
