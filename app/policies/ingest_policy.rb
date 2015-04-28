class IngestPolicy < ApplicationPolicy

  def index?
    admin_or_backend_role?
  end

  def show?
    admin_or_backend_role?
  end

  def edit?
    admin_or_backend_role?
  end

  def update?
    admin_or_backend_role?
  end

  def destroy?
    admin_or_backend_role?
  end

  def count?
    admin_or_backend_role?
  end

  def permitted_attributes
    if update?
      [:messages, :stage, :iteration, :busy, :terminate,
        :document_attributes => [:id, :track_attributes => [:s3_url]]]
    end
  end

end