class AddIterationToIngests < ActiveRecord::Migration
  def change
    add_column :ingests, :iteration, :integer, null: false, default: 0
    add_index :ingests, :iteration
  end
end
