class RoadsideAssistanceEventPolicy < ApplicationPolicy
  def index?
    user.admin? || user.mecanico? || user.superadmin? || user.chofer?
  end

  def show?
    record.company_id == user.company_id && (user.admin? || user.mecanico? || user.superadmin? || record.user_id == user.id)
  end

  def create?
    user.chofer? || user.admin? || user.superadmin?
  end

  def update?
    user.admin? || user.mecanico? || user.superadmin?
  end

  def destroy?
    user.admin? || user.superadmin?
  end

  class Scope < Scope
    def resolve
      if user.admin? || user.mecanico? || user.superadmin?
        scope.where(company_id: user.company_id)
      elsif user.chofer?
        scope.where(company_id: user.company_id, user_id: user.id)
      else
        scope.none
      end
    end
  end
end
