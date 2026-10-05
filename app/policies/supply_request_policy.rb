class SupplyRequestPolicy < ApplicationPolicy
  def index?
    user.superadmin? || user.admin? || user.mecanico? || user.analista? || user.bodeguero?
  end

  def show?
    same_company? && (user.superadmin? || user.admin? || user.mecanico? || user.analista? || user.bodeguero?)
  end

  def create?
    user.mecanico? || user.admin? || user.superadmin?
  end

  def update?
    same_company? && (user.admin? || user.superadmin? || user.bodeguero?)
  end

  def destroy?
    same_company? && (user.admin? || user.superadmin?)
  end

  def change_status?
    same_company? && (user.admin? || user.superadmin? || user.bodeguero?)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.superadmin? || user.admin? || user.analista? || user.bodeguero?
        company_scoped
      elsif user.mecanico?
        company_scoped.where(user: user)
      else
        scope.none
      end
    end
  end
end
