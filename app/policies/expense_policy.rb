class ExpensePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user.superadmin? || user.admin?
        company_scoped
      elsif user.analista?
        company_scoped.where(restricted_access: false)
      else
        scope.none
      end
    end
  end

  def index?
    user.superadmin? || user.admin? || user.analista?
  end

  def show?
    return false unless same_company?
    user.superadmin? || user.admin? || (user.analista? && !record.restricted_access)
  end

  def create?
    user.superadmin? || user.admin?
  end

  def update?
    same_company? && (user.superadmin? || user.admin?)
  end

  def destroy?
    update?
  end
end
