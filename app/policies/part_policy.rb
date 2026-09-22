class PartPolicy < ApplicationPolicy
  def index?
    user.superadmin? || user.admin? || user.mecanico? || user.analista?
  end

  def show?
    index?
  end

  def create?
    user.superadmin? || user.admin?
  end

  def update?
    create?
  end

  def destroy?
    create?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      allowed = user.superadmin? || user.admin? || user.mecanico? || user.analista?
      allowed ? scope.all : scope.none
    end
  end
end
