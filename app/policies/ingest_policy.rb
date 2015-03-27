class IngestPolicy < ApplicationPolicy

  def index?
    backend_role?
  end

  def show?
    backend_role?
  end

  def edit?
    backend_role?
  end

  def update?
    backend_role?
  end

  def destroy?
    backend_role?
  end

  def count?
    backend_role?
  end

  protected

  def backend_role?
    user.roles.include?(:backend)
  end

end