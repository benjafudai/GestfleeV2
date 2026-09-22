class FuelFillPolicy < ApplicationPolicy
  def index?
    admin_or_superadmin? || chofer?
  end

  def show?
    same_company? && (admin_or_superadmin? || record.user_id == user.id)
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
      if user.superadmin?
        scope.all
      elsif user.admin?
        scope.where(company_id: user.company_id)
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

  def same_company?
    user.superadmin? || record.company_id == user.company_id
  end
end
