class CreateDocumentIngests < ActiveRecord::Migration
  def change
    create_table :document_ingests do |t|
      t.integer :upload_id
      t.string :locale, :limit => 5, :default => "en-US", :null => false
      t.integer :privacy_mask,  :default => 0, :null => false
      t.timestamps
    end
    add_index :document_ingests, :upload_id
    add_index :document_ingests, :locale
    add_index :document_ingests, :privacy_mask
  end
end
