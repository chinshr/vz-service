class AddIndexOnScoreForDocumentChunks < ActiveRecord::Migration
  def change
    add_index :document_chunks, :score
  end
end
