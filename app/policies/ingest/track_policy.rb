class Ingest::TrackPolicy < TrackPolicy
  def create?
    backend_role?
  end

  def update?
    backend_role?
  end

  def index?
    backend_role?
  end

  def show?
    backend_role?
  end

  def destroy?
    backend_role?
  end

  def permitted_attributes
    super + [:s3_url, :s3_mp3_url, :ingest_iteration, :s3_waveform_url]
  end
end