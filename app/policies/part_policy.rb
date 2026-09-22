class PartPolicy < ApplicationPolicy
  def index?
    user.admin? || user.mecanico? || user.analista?
  end

  def show?
    user.admin? || user.mecanico? || user.analista?
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

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin? || user.mecanico? || user.analista?
        scope.all
      else
        scope.none
      end
    end
  end
end
