class AddUidToIngests < ActiveRecord::Migration
  def change
    add_column :ingests, :uid, :string
    add_index :ingests, :uid
  end
end
