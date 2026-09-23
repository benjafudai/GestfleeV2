class ChecklistTemplatePolicy < ApplicationPolicy
  def index?
    user.admin? || user.analista? || user.superadmin?
  end

  def show?
    user.admin? || user.analista? || user.superadmin?
  end

  def create?
    user.admin? || user.superadmin?
  end

  def update?
    user.admin? || user.superadmin?
  end

  def destroy?
    user.admin? || user.superadmin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      company_scoped
    end
  end
end
