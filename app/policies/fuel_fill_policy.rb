class FuelFillPolicy < ApplicationPolicy
  def index?
    admin_or_superadmin? || chofer? || analista?
  end

  def show?
    same_company? && (admin_or_superadmin? || analista? || record.user_id == user.id)
  end

  def new?
    create?
  end

  def create?
    chofer? || admin_or_superadmin?
  end

  def edit?
    same_company? && admin_or_superadmin?
  end

  def update?
    same_company? && admin_or_superadmin?
  end

  def destroy?
    same_company? && admin_or_superadmin?
  end

  class Scope < Scope
    def resolve
      if user.superadmin? || user.admin? || user.analista?
        company_scoped
      else
        scope.where(user_id: user.id)
      end
    end
  end

  private

  def admin_or_superadmin?
    user.admin? || user.superadmin?
  end

  def chofer?
    user.chofer?
  end

  def analista?
    user.analista?
  end
end
