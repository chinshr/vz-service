class AddTimestampsToSegments < ActiveRecord::Migration
  def change
    add_column :segments, :updated_at, :datetime
    add_column :segments, :created_at, :datetime
    add_index :segments, :created_at
  end
end
