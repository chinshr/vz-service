class AddHandleToIngests < ActiveRecord::Migration
  def change
    add_column :ingests, :handle, :string
    add_index :ingests, :handle
  end
end
