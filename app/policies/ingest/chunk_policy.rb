class Ingest::ChunkPolicy < ChunkPolicy
  def create?
    backend_role?
  end

  def update?
    backend_role?
  end

  def permitted_attributes
    super + [:ingest_iteration, track_attributes: [:s3_url, :s3_mp3_url]]
  end
end