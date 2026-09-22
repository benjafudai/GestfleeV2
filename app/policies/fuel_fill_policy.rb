class FuelFillPolicy < ApplicationPolicy
  def index?
    admin_or_superadmin? || chofer?
  end

  def show?
    admin_or_superadmin? || record.user_id == user.id
  end

  def new?
    true # Depends on user, chofer can create
  end

  def create?
    true
  end

  def edit?
    admin_or_superadmin?
  end

  def update?
    admin_or_superadmin?
  end

  def destroy?
    admin_or_superadmin?
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
end
