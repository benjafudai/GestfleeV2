class ExpensePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      elsif user.analista?
        scope.where(restricted_access: false)
      else
        scope.none
      end
    end
  end

  def index?
    user.admin? || user.analista?
  end

  def show?
    user.admin? || (user.analista? && !record.restricted_access)
  end

  def create?
    user.admin?
  end

  def update?
    user.admin?
  end

  def destroy?
    user.admin?
  end
end
