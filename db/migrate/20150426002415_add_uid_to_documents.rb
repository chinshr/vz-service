class AddUidToDocuments < ActiveRecord::Migration
  def change
    add_column :documents, :uid, :string
    add_index :documents, :uid
  end
end
