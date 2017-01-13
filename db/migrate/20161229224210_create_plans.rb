class CreatePlans < ActiveRecord::Migration
  def change
    create_table :plans do |t|
      t.string :uid
      t.string :name
      t.string :stripe_id
      t.string :interval
      t.integer :amount
      t.text :features
      t.string :highlight
      t.integer :display_order
      t.boolean :enabled, null: false, default: false
      t.boolean :visible, null: false, default: false
      t.boolean :create_stripe, null: false, default: false
      t.json :metadata, default: {}, null: false
      t.timestamps null: false
    end
    add_index :plans, :uid
    add_index :plans, :stripe_id
    add_index :plans, :display_order
    add_index :plans, :enabled
    add_index :plans, :visible
    add_index :plans, :create_stripe
  end
end
