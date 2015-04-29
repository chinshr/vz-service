class TrackPolicy < ApplicationPolicy
  def index?
    backend_role?
  end

  def create?
    backend_role?
  end

  def show?
    backend_role?
  end

  def update?
    backend_role?
  end

  def destroy?
    backend_role?
  end

  def permitted_attributes
    [:s3_url, :s3_mp3_url]
  end
end