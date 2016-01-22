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

  def permitted_attributes(action_name = nil)
    if update? && action_name == "update"
      [:iteration, :busy, :terminate, :progress, :status, :event, :trigger, :file_type, :file_size, :origin_url,
        :document_attributes => [:id, :track_attributes => [:s3_url]]]
    else
      []
    end
  end

end