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

  def permitted_attributes
    if update?
      [:stage, :iteration, :busy, :terminate, :progress, :status, :event,
        :document_attributes => [:id, :track_attributes => [:s3_url]]]
    else
      []
    end
  end

end