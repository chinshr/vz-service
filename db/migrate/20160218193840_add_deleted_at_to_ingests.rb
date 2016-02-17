class AddDeletedAtToIngests < ActiveRecord::Migration
  def change
    add_column :ingests, :deleted_at, :datetime
    add_index :ingests, :deleted_at
  end
end
