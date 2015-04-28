class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    scope.where(:id => record.id).exists?
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  def backend_role?
    !!(user && (user.backend_role? || user.admin_role?))
  end

  def admin_role?
    !!(user && user.admin_role?)
  end

  def developer_role?
    !!(user && user.developer_role?)
  end

  def admin_or_backend_role?
    admin_role? || backend_role?
  end

  def owner_of?(record)
    !!(user && user.owner_of?(record))
  end

  def scope
    Pundit.policy_scope!(user, record.class)
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope
    end
  end
end

