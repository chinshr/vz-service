class AddProgressToIngests < ActiveRecord::Migration
  def change
    add_column :ingests, :progress, :integer, :default => 0, :null => false
  end
end
