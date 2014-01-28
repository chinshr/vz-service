class AddStageToIngests < ActiveRecord::Migration
  def change
    add_column :ingests, :stage, :string
    add_index :ingests, :stage
  end
end
