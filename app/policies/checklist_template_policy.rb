class ChecklistTemplatePolicy < ApplicationPolicy
  def index?
    user.admin? || user.analista?
  end

  def show?
    user.admin? || user.analista?
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
      scope.all
    end
  end
end
