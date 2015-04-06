class CreateApiClients < ActiveRecord::Migration
  def change
    create_table :api_clients do |t|
      t.string :name
      t.string :key, null: false
      t.integer :platform_id
      t.timestamps
    end
    add_index :api_clients, :platform_id
    add_index :api_clients, :key, unique: true
  end
end
