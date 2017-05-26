class AddKeyToPlans < ActiveRecord::Migration
  def up
    add_column :plans, :key, :string
  end

  def down
    remove_column :plans, :key
  end
end
