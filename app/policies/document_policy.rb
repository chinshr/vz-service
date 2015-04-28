class DocumentPolicy < ApplicationPolicy

  def create?
    admin_or_backend_role?
  end

  def show?
    admin_or_backend_role? || (record.privacy_private? ? owner_of?(record) : true)
  end

  def edit?
    admin_or_backend_role? || owner_of?(record)
  end

  def update?
    admin_or_backend_role? || owner_of?(record)
  end

  def destroy?
    admin_or_backend_role? || owner_of?(record)
  end

end