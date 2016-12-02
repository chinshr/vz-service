class ChangeDocumentsResponseColumnDefaultJson < ActiveRecord::Migration
  def up
    execute %(
      UPDATE documents SET response = '{}'::json WHERE response IS NULL;
    )
    execute %(
      ALTER TABLE documents
        ALTER COLUMN response TYPE jsonb USING response::jsonb,
        ALTER COLUMN response SET NOT NULL,
        ALTER COLUMN response DROP DEFAULT;
    )
    change_column :documents, :response, :jsonb, default: {}
    add_index :documents, :response, using: :gin
  end

  def down
    remove_index :documents, :response
    change_column :documents, :response, 'json USING CAST(response AS json)'
  end
end
