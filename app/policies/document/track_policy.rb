class Document::TrackPolicy < TrackPolicy
  def index?
    backend_role? || developer_role?
  end

  def show?
    backend_role? || developer_role?
  end

  def permitted_attributes
    super + []
  end
end