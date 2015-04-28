class TrackPolicy < ApplicationPolicy
  def index?
    admin_or_backend_role?
  end

  def create?
    admin_or_backend_role?
  end

  def show?
    admin_or_backend_role?
  end

  def edit?
    admin_or_backend_role?
  end

  def update?
    admin_or_backend_role?
  end

  def destroy?
    admin_or_backend_role?
  end
end