class DocumentPolicy < ApplicationPolicy
  
  def show?
    record.privacy_private? ? !!(user && record.user && user == record.user) : true
  end
  
  def edit?
    !!(user && record.user && user == record.user)
  end
  
  def update?
    !!(user && record.user && user == record.user)
  end

  def destroy?
    !!(user && record.user && user == record.user)
  end
  
end