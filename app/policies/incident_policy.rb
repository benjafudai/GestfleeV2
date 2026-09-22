class IncidentPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    user.admin? || user.mecanico? || user.superadmin? || record.reporter == user
  end

  def create?
    user.chofer? || user.admin? || user.superadmin?
  end

  def update?
    user.admin? || user.mecanico? || user.superadmin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin? || user.mecanico? || user.superadmin?
        scope.all
      else
        scope.where(reporter: user)
      end
    end
  end
end
