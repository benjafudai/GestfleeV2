class SupplyRequestPolicy < ApplicationPolicy
  # NOTE: Up to Pundit v2.3.1, the inheritance was declared as
  def index?
    user.admin? || user.mecanico? || user.analista?
  end

  def show?
    user.admin? || user.mecanico? || user.analista?
  end

  def create?
    user.mecanico? || user.admin?
  end

  def update?
    user.admin?
  end

  def destroy?
    user.admin?
  end

  def change_status?
    user.admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin? || user.analista?
        scope.joins(:vehicle)
      elsif user.mecanico?
        scope.joins(:vehicle).where(user: user)
      else
        scope.none
      end
    end
  end
end
