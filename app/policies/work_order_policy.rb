class WorkOrderPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      user.superadmin? ? scope.all : scope.where(company: user.company)
    end
  end

  def index?
    user.superadmin? || user.admin? || user.mecanico?
  end

  def show?
    index?
  end

  def create?
    index?
  end

  def update?
    index?
  end

  def destroy?
    user.superadmin? || user.admin?
  end

  def change_status?
    index?
  end
end
