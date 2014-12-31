class RenameContentToHtmlInDocuments < ActiveRecord::Migration
  def change
    rename_column :documents, :content, :html
  end
end
