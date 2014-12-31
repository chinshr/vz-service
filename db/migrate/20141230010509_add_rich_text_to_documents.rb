class AddRichTextToDocuments < ActiveRecord::Migration
  def change
    add_column :documents, :rich_text, :text
  end
end
