class ChunkPolicy < IngestPolicy
  def create?
    admin_or_backend_role?
  end
end