class AddProgressToIngests < ActiveRecord::Migration
  def change
    add_column :ingests, :progress, :float, :default => 0.0, :null => false
  end
end
