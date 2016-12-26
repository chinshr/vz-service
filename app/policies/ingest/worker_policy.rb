class Ingest::WorkerPolicy < ApplicationPolicy
  def create?
    backend_role?
  end

  def update?
    backend_role?
  end

  def index?
    backend_role?
  end

  def show?
    backend_role?
  end

  def destroy?
    backend_role?
  end

  def count?
    backend_role?
  end

  def permitted_attributes(action_name = nil)
    keys = [:ingest_iteration, :worker_name, :event, :status, :instance_id, :progress, :lock_count, :worker_object_id]
    keys
  end
end
