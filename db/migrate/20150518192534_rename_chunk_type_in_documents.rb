class RenameChunkTypeInDocuments < ActiveRecord::Migration
  CHUNK_NAMES = ['Chunk::AttSpeech', 'Chunk::GoogleSpeech', 'Chunk::MechanicalTurk', 'Chunk::NuanceDragon', 'Chunk::Pocketsphinx']

  def up
    CHUNK_NAMES.each do |chunk_name|
      execute "UPDATE documents SET type = '#{chunk_name}Chunk' WHERE documents.type = '#{chunk_name}'"
      execute "UPDATE turkee_tasks SET task_type = '#{chunk_name}Chunk' WHERE turkee_tasks.task_type = '#{chunk_name}'"
    end
  end

  def down
    CHUNK_NAMES.each do |chunk_name|
      execute "UPDATE documents SET type = '#{chunk_name}' WHERE documents.type = '#{chunk_name}Chunk'"
      execute "UPDATE turkee_tasks SET task_type = '#{chunk_name}' WHERE turkee_tasks.task_type = '#{chunk_name}Chunk'"
    end
  end
end
