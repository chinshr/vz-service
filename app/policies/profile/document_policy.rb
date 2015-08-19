class Profile::DocumentPolicy < ApplicationPolicy

  def show?
    record.published?
  end

  def publish?
    owner_of?(record)
  end

end