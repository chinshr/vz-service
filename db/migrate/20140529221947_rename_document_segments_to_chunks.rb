class RenameDocumentSegmentsToChunks < ActiveRecord::Migration
  def up
    rename_table "document_segments", "document_chunks"
    
    execute "UPDATE document_chunks SET type = 'Document::Chunk::AttSpeech' WHERE document_chunks.type = 'Document::Segment::AttSpeech'"
    execute "UPDATE document_chunks SET type = 'Document::Chunk::GoogleSpeech' WHERE document_chunks.type = 'Document::Segment::GoogleSpeech'"
    execute "UPDATE document_chunks SET type = 'Document::Chunk::NuanceDragon' WHERE document_chunks.type = 'Document::Segment::NuanceDragon'"
  end

  def down
    execute "UPDATE document_chunks SET type = 'Document::Segment::AttSpeech' WHERE document_chunks.type = 'Document::Chunk::AttSpeech'"
    execute "UPDATE document_chunks SET type = 'Document::Segment::GoogleSpeech' WHERE document_chunks.type = 'Document::Chunk::GoogleSpeech'"
    execute "UPDATE document_chunks SET type = 'Document::Segment::NuanceDragon' WHERE document_chunks.type = 'Document::Chunk::NuanceDragon'"

    rename_table "document_chunks", "document_segments"
  end
end
