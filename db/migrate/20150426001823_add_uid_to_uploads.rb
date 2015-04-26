class AddUidToUploads < ActiveRecord::Migration
  def change
    add_column :uploads, :uid, :string
    add_index :uploads, :uid
  end
end
