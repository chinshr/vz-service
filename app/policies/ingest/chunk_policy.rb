class Ingest::ChunkPolicy < ChunkPolicy

  def create?
    backend_role?
  end

  def update?
    backend_role?
  end

  def permitted_attributes(action_name = nil)
    track_attributes = policy(:"ingest/track").permitted_attributes(action_name)
    super(action_name) + [:ingest_iteration, :document_id, {words: []}, {chunk_ids: []}, {track_attributes: track_attributes}]
  end
end