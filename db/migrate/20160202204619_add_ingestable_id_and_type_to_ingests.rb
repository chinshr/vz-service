class AddIngestableIdAndTypeToIngests < ActiveRecord::Migration
  def change
    add_column :ingests, :ingestable_id, :integer
    add_column :ingests, :ingestable_type, :string
    add_index :ingests, [:ingestable_id, :ingestable_type]
  end
end
