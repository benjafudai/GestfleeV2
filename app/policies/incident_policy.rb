class IncidentPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    same_company? && (user.admin? || user.mecanico? || user.superadmin? || record.reporter == user)
  end

  def create?
    user.chofer? || user.admin? || user.superadmin?
  end

  def update?
    same_company? && (user.admin? || user.mecanico? || user.superadmin?)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.superadmin?
        scope.all
      elsif user.admin? || user.mecanico?
        scope.where(company_id: user.company_id)
      else
        scope.where(reporter: user)
      end
    end
  end
end
