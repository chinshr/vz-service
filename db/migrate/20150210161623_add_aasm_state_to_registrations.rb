class AddAasmStateToRegistrations < ActiveRecord::Migration
  def change
    add_column :registrations, :aasm_state, :string, default: "pending", null: false
    add_column :registrations, :accepted_at, :datetime
    add_column :registrations, :declined_at, :datetime

    add_index :registrations, :aasm_state
  end
end
