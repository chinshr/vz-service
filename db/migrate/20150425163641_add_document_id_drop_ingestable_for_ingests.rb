class AddDocumentIdDropIngestableForIngests < ActiveRecord::Migration
  def up
    add_column :ingests, :document_id, :integer
    add_index :ingests, :document_id
    remove_column :ingests, :ingestable_id
    remove_column :ingests, :ingestable_type
  end

  def down
    add_column :ingests, :ingestable_id, :integer
    add_column :ingests, :ingestable_type, :string
    add_index :ingests, [:ingestable_id, :ingestable_type]
    remove_column :ingests, :document_id
  end
end
