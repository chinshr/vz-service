class RemoveWordsFromDocuments < ActiveRecord::Migration
  def up
    remove_column :documents, :words
  end

  def down
    add_column :documents, :words, :json, default: []
  end
end
