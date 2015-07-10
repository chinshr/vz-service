class RenameDocumentsSlugToSlugId < ActiveRecord::Migration
  def change
    rename_column :documents, :slug, :slug_id
  end
end
