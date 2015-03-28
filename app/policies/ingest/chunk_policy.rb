class Ingest::ChunkPolicy < IngestPolicy
  def create?
    backend_role?
  end
end