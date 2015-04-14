class CreateApiDevices < ActiveRecord::Migration
  def change
    create_table :api_devices do |t|
      t.string :device_name
      t.string :uid, null: false
      t.integer :client_id
      t.integer :client_access_id
      t.timestamps
    end
    add_index :api_devices, :uid, unique: true
    add_index :api_devices, :client_id
    add_index :api_devices, :client_access_id
  end
end
