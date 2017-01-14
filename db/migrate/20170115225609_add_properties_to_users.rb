class AddPropertiesToUsers < ActiveRecord::Migration
  def change
    add_column :users, :properties, :jsonb, default: {}, null: false
  end
end
