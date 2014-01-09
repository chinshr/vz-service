class CreateIngests < ActiveRecord::Migration
  def change
    create_table :ingests do |t|
      t.integer :upload_id
      t.integer :ingestable_id
      t.string :ingestable_type
      t.string :type
      t.string :aasm_state, :null => false, :default => "created"
      t.timestamps
    end
    
    add_index :ingests, :upload_id
    add_index :ingests, [:ingestable_id, :ingestable_type]
    add_index :ingests, :type
    add_index :ingests, :aasm_state
    add_index :ingests, :created_at
    add_index :ingests, :updated_at
  end
end
