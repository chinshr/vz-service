class AddSessionIdToUploads < ActiveRecord::Migration
  def change
    add_column :uploads, :session_id, :integer
    add_index :uploads, :session_id
  end
end
