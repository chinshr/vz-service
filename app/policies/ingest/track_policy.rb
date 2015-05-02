class Ingest::TrackPolicy < TrackPolicy
  def create?
    backend_role?
  end

  def update?
    backend_role?
  end

  def permitted_attributes
    super + [:s3_url, :s3_mp3_url, :ingest_iteration]
  end
end