class DocumentPolicy < ApplicationPolicy

  def create?
    backend_role?
  end

  def show?
    backend_role? || owner_of?(record) || record.accessibility_viewable? || (record.published? && !record.privacy_private?)
  end

  def edit?
    backend_role? || owner_of?(record) || record.accessibility_editable?
  end

  def update?
    backend_role? || owner_of?(record) || record.accessibility_editable?
  end

  def destroy?
    backend_role? || owner_of?(record)
  end

  def publish?
    owner_of?(record)
  end

  def permitted_attributes(controller = nil)
    [:title, :description, {:tag_list => []}, :locale, :privacy, :accessibility, :html, :rich_text, :text, :status, :event]
  end
end