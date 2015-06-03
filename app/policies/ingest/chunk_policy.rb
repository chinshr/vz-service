class Ingest::ChunkPolicy < ChunkPolicy

  def create?
    backend_role?
  end

  def update?
    backend_role?
  end

  def permitted_attributes
    track_attributes = policy(:"ingest/track").permitted_attributes
    super + [:ingest_iteration, :chunk_ids => [], track_attributes: track_attributes]
  end
end