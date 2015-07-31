class Profile::DocumentPolicy < ApplicationPolicy

  def show?
    record.published?
  end

end