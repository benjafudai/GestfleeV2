class SupplyRequestPolicy < ApplicationPolicy
  def index?
    user.superadmin? || user.admin? || user.mecanico? || user.analista?
  end

  def show?
    same_company? && (user.superadmin? || user.admin? || user.mecanico? || user.analista?)
  end

  def create?
    user.mecanico? || user.admin?
  end

  def update?
    same_company? && user.admin?
  end

  def destroy?
    same_company? && user.admin?
  end

  def change_status?
    same_company? && user.admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.superadmin? || user.admin? || user.analista?
        company_scoped
      elsif user.mecanico?
        company_scoped.where(user: user)
      else
        scope.none
      end
    end
  end
end
