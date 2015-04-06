class CreateApiClientAccesses < ActiveRecord::Migration
  def change
    create_table :api_client_accesses do |t|
      t.string :uid, null: false
      t.integer :client_id
      t.string :access_secret
      t.integer :user_id
      t.string :device_uid
      t.string :device_user_uid
      t.string :aasm_state, default: "inactive", null: false
      t.integer :access_status
      t.datetime :activated_at
      t.datetime :deactivated_at
      t.datetime :deleted_at
      t.timestamps
    end
    add_index :api_client_accesses, :uid, unique: true
    add_index :api_client_accesses, :client_id
    add_index :api_client_accesses, :user_id
    add_index :api_client_accesses, :aasm_state
    add_index :api_client_accesses, :access_status
    add_index :api_client_accesses, :deleted_at
  end
end
