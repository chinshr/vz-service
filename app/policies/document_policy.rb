class DocumentPolicy < ApplicationPolicy

  def create?
    backend_role?
  end

  def show?
    backend_role? || (record.privacy_private? ? owner_of?(record) : true)
  end

  def edit?
    backend_role? || owner_of?(record)
  end

  def update?
    backend_role? || owner_of?(record)
  end

  def destroy?
    backend_role? || owner_of?(record)
  end

end