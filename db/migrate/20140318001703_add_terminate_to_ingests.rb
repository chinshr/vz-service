class AddTerminateToIngests < ActiveRecord::Migration
  def change
    add_column :ingests, :terminate, :boolean, default: false, null: false
  end
end
