class CreateApiPlatforms < ActiveRecord::Migration
  def change
    create_table :api_platforms do |t|
      t.string :uid, null: false
      t.string :name
      t.string :version
      t.string :aasm_state, default: "inactive", null: false
      t.boolean :cap, default: false, null: false
      t.datetime :activated_at
      t.datetime :deactivated_at
      t.timestamps
    end
    add_index :api_platforms, :uid, unique: true
    add_index :api_platforms, :aasm_state
  end
end
