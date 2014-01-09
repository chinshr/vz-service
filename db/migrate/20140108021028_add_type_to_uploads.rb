class AddTypeToUploads < ActiveRecord::Migration
  def change
    add_column :uploads, :type, :string
    add_index :uploads, :type
  end
end
