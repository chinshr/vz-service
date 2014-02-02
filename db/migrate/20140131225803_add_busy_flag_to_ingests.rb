class AddBusyFlagToIngests < ActiveRecord::Migration
  def change
    add_column :ingests, :busy, :boolean, :default => false, :null => false
  end
end
