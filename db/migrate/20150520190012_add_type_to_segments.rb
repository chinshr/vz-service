class AddTypeToSegments < ActiveRecord::Migration
  def change
    add_column :segments, :type, :string
    add_index :segments, :type
  end
end
