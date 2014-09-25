class RemoveSessionIdFromUploads < ActiveRecord::Migration
  def up
    remove_column :uploads, :session_id
  end
  
  def down
    add_column :uploads, :session_id, :integer
    add_index :uploads, :session_id
  end
end
