class Profile::DocumentPolicy < ApplicationPolicy

  def show?
    !record.privacy_private? && record.published?
  end

  def publish?
    owner_of?(record)
  end

end