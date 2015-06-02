class AddColumnIsMasterToSegments < ActiveRecord::Migration
  def change
    add_column :segments, :is_master, :boolean, null: false, default: false
    add_index :segments, :is_master
  end
end
