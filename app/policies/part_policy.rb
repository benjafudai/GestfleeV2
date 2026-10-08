class PartPolicy < ApplicationPolicy
  def index?
    user.superadmin? || user.admin? || user.mecanico? || user.analista? || user.bodeguero?
  end

  def show?
    index?
  end

  def create?
    user.superadmin? || user.admin? || user.bodeguero?
  end

  def update?
    create?
  end

  # Bodeguero manages stock but can't delete parts from the catalog.
  def destroy?
    user.superadmin? || user.admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      allowed = user.superadmin? || user.admin? || user.mecanico? || user.analista? || user.bodeguero?
      allowed ? company_scoped : scope.none
    end
  end
end
