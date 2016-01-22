class AddWordsToDocuments < ActiveRecord::Migration
  def change
    add_column :documents, :words, :json, default: []
  end
end
